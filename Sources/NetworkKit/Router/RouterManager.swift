
import Foundation

public final class RouterManager<T: Router> {
  private let router: T
  private let requestType: RequestType

  private let diskCacheLoader: CacheLoader = DiskCacheLoader.shared
  private let memoryCacheLoader: CacheLoader = MemoryCacheLoader.shared

  public init(
    router: T,
    requestType: RequestType = .remote
  ) {
    self.router = router
    self.requestType = requestType
  }

  /// 요청을 보냅니다.
  /// - Returns: 요청 결과 데이터
  public func request() async throws -> Data {
    switch requestType {
    case .remote:
      return try await sendRequest(router: router)
    case .cache:
      return try await cacheRequest(router: router)
    case .stub, .delayed:
      return try await stubRequest(router: router)
    }
  }
}

fileprivate extension RouterManager {
  /// 요청을 보냅니다.
  /// - Parameter router: 라우터
  /// - Returns: 요청 결과 데이터
  func sendRequest(router: T) async throws -> Data {
    let urlRequest = try createURLRequest(router: router)

    if let url = urlRequest.url, router.method.isEnableEtag {
      let container = try await fetchCache(
        for: url,
        enableDiskCache: router.method.isEnableDiskCache
      )
      return try await requestWithCache(
        urlRequest: urlRequest,
        isEnableEtag: router.method.isEnableEtag,
        isEnableDiskCache: router.method.isEnableDiskCache,
        container: container
      )
    } else {
      return try await requestWithCache(
        urlRequest: urlRequest,
        isEnableEtag: router.method.isEnableEtag,
        isEnableDiskCache: router.method.isEnableDiskCache,
        container: nil
      )
    }
  }
  
  /// stub을 반환합니다.
  /// - Parameter router: 라우터
  /// - Returns: stub 데이터
  func stubRequest(router: T) async throws -> Data {
    switch requestType {
    case .remote, .cache:
      throw RouterManagerErrorFactory.requestTypeError()
    case .stub:
      return router.sampleData
    case let .delayed(delay):
      try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
      return router.sampleData
    }
  }

  /// 캐시를 요청합니다.
  /// - Note: 디스크 캐시는 메모리 캐시가 없을 경우에만 확인합니다. (우선순위: 메모리 캐시 -> 디스크 캐시)
  /// 디스크 캐시에서 캐시가 조회되면, 메모리 캐시에 저장합니다.
  /// - Parameter router: 라우터
  /// - Returns: 캐시된 데이터
  /// - Throws: 캐시 조회 실패 시. (캐시가 없을 경우.)
  func cacheRequest(router: T) async throws -> Data {
    let urlRequest = try createURLRequest(router: router)
    
    guard let url = urlRequest.url else {
      throw RouterManagerErrorFactory.urlIsNil()
    }

    let container = try await fetchCache(
      for: url,
      enableDiskCache: router.method.isEnableDiskCache
    )

    return container.data
  }
}

fileprivate extension RouterManager {
  /// 캐시를 가져옵니다.
  /// - Note: 디스크 캐시는 메모리 캐시가 없을 경우에만 확인합니다. (우선순위: 메모리 캐시 -> 디스크 캐시)
  /// 디스크 캐시에서 캐시가 조회되면, 메모리 캐시에 저장합니다.
  /// - Parameters:
  ///   - url: 요청 URL
  ///   - enableDiskCache: 디스크 캐시 사용 여부
  /// - Returns: 캐시된 데이터
  /// - Throws: 캐시 조회 실패 시. (캐시가 없을 경우.)
  private func fetchCache(
    for url: URL,
    enableDiskCache: Bool
  ) async throws -> CacheContainer {
    // 메모리 캐시에서 캐시를 조회합니다.
    do {
      return try await memoryCacheLoader.get(for: url.absoluteString)
    } catch {
      guard enableDiskCache else { throw error }
      
      // 메모리 캐시에서 캐시를 조회하지 못했고, 디스크 캐시가 활성화되어 있을 경우, 디스크 캐시에서 캐시를 조회합니다.
      let container = try await diskCacheLoader.get(for: url.absoluteString)
      
      // 디스크 캐시에서 캐시를 조회했을 경우, 메모리 캐시에 저장합니다.
      do {
        try await memoryCacheLoader.save(for: url.absoluteString, container)
      } catch {
        Logger.log("디스크 캐시에서 캐시를 조회했지만, 메모리 캐시 저장에 실패했습니다: %s", error)
      }
      
      return container
    }
  }

  /// 요청을 보냅니다.
  /// - Note: 캐시가 존재할 경우, Etag를 통해 변경 사항이 있는지 확인합니다.
  /// 변경 사항이 없을 경우, 캐시 데이터를 반환합니다.
  /// 변경 사항이 있을 경우, 캐시를 저장하고 데이터를 반환합니다.
  /// - Parameters:
  ///   - urlRequest: URL 요청
  ///   - isEnableEtag: Etag 사용 여부
  ///   - isEnableDiskCache: 디스크 캐시 사용 여부
  ///   - container: 캐시
  /// - Returns: 요청 결과 데이터
  private func requestWithCache(
    urlRequest: URLRequest,
    isEnableEtag: Bool,
    isEnableDiskCache: Bool,
    container: CacheContainer?
  ) async throws -> Data {
    var urlRequest = urlRequest

    if let etag = container?.etag, isEnableEtag {
      urlRequest.setValue(etag, forHTTPHeaderField: "If-None-Match")
    }

    let (data, response) = try await URLSession.shared.data(for: urlRequest)
    
    guard let httpResponse = response as? HTTPURLResponse else {
      throw RouterManagerErrorFactory.urlResponseIsNil()
    }

    if let container = container {
      if 304 == httpResponse.statusCode {
        return container.data
      }
    }

    if (200 ..< 300) ~= httpResponse.statusCode {
      guard let url = urlRequest.url else {
        throw RouterManagerErrorFactory.urlIsNil()
      }

      if isEnableEtag {
        let etag = httpResponse.allHeaderFields["Etag"] as? String
        do {
          try await saveCache(
            for: url,
            enableDiskCache: isEnableDiskCache,
            container: .init(data: data, etag: etag)
          )
        } catch {
          Logger.log("캐시 저장에 실패했습니다: %s", error)
        }
      }
      
      return data
    }

    throw RouterManagerErrorFactory.badResponse(httpResponse)
  }

  /// 캐시를 저장합니다.
  /// - Note: 캐시를 저장합니다.
  /// 메모리 캐시에 우선 저장하며 디스크 캐시가 활성화되어 있을 경우, 디스크 캐시에도 저장합니다.
  /// - Parameters:
  ///   - url: 요청 URL
  ///   - enableDiskCache: 디스크 캐시 사용 여부
  ///   - container: 캐시
  private func saveCache(
    for url: URL,
    enableDiskCache: Bool,
    container: CacheContainer
  ) async throws {
    do {
      try await memoryCacheLoader.save(for: url.absoluteString, container)
    } catch {
      if !enableDiskCache {
        throw error
      }
      Logger.log("메모리 캐시 저장에 실패했습니다: %s", error)
    }

    if enableDiskCache {
      try await diskCacheLoader.save(for: url.absoluteString, container)
    }
  }

  /// URLRequest를 생성합니다.
  /// - Parameters:
  ///   - router: 라우터
  /// - Returns: URL 요청
  private func createURLRequest(router: T) throws -> URLRequest {
    switch router.task {
    case .requestPlain:
      var urlRequest = URLRequest(url: router.baseURL.appendingPathComponent(router.path))
      urlRequest.httpMethod = router.method.rawValue
      urlRequest.allHTTPHeaderFields = router.headers
      urlRequest.httpBody = nil
      if router.method.isEnableEtag {
        urlRequest.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
      }
      return urlRequest
      
    case let .requestJSONEncodable(encodable):
      var urlRequest = URLRequest(url: router.baseURL.appendingPathComponent(router.path))
      urlRequest.httpMethod = router.method.rawValue
      urlRequest.allHTTPHeaderFields = router.headers
      urlRequest.httpBody = try JSONEncoder().encode(encodable)
      if router.method.isEnableEtag {
        urlRequest.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
      }
      return urlRequest
      
    case let .requestCustomJSONEncodable(encodable, encoder):
      var urlRequest = URLRequest(url: router.baseURL.appendingPathComponent(router.path))
      urlRequest.httpMethod = router.method.rawValue
      urlRequest.allHTTPHeaderFields = router.headers
      urlRequest.httpBody = try encoder.encode(encodable)
      if router.method.isEnableEtag {
        urlRequest.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
      }
      return urlRequest
      
    case let .requestParameters(parameters, type):
      switch type {
      case .body:
        var urlRequest = URLRequest(url: router.baseURL.appendingPathComponent(router.path))
        urlRequest.httpMethod = router.method.rawValue
        urlRequest.allHTTPHeaderFields = router.headers
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
        if router.method.isEnableEtag {
          urlRequest.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        }
        return urlRequest

      case .query:
        var components = URLComponents(url: router.baseURL.appendingPathComponent(router.path), resolvingAgainstBaseURL: false)
        components?.queryItems = parameters.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
        guard let url = components?.url else { throw RouterManagerErrorFactory.urlIsNil() }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = router.method.rawValue
        urlRequest.allHTTPHeaderFields = router.headers
        if router.method.isEnableEtag {
          urlRequest.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        }
        return urlRequest
      }
    }
  }
}

public enum RequestType {
  /// 원격 요청을 사용합니다.
  case remote
  
  /// 캐시를 사용합니다.
  case cache

  /// stub을 사용합니다.
  case stub

  /// 딜레이 이후 stub을 return합니다.
  case delayed(seconds: TimeInterval)
}
