
import Foundation

/// 정의된 ``Router`` 에 따른 요청 처리를 담당합니다.
public final class RouterManager<T: Router> {
  private let diskCacheLoader: CacheLoader = DiskCacheLoader.shared
  private let memoryCacheLoader: CacheLoader = MemoryCacheLoader.shared

  private let interceptor: Interceptor
  private let retrier: Retrier
  private let networkEventMonitor: NetworkEventMonitor?

  /// ``RouterManager``를 생성합니다.
  /// - Parameters:
  ///   - interceptor: 해당 라우터에서 사용할 ``Interceptor``
  ///   - retrier: 해당 라우터에서 사용할 ``Retrier``
  ///   - networkEventMonitor: 해당 라우터에서 사용할 ``NetworkEventMonitor``
  public init(
    interceptor: Interceptor = DefaultInterceptor(),
    retrier: Retrier = DefaultRetrier(),
    networkEventMonitor: NetworkEventMonitor? = nil
  ) {
    self.interceptor = interceptor
    self.retrier = retrier
    self.networkEventMonitor = networkEventMonitor
  }

  /// 요청을 보냅니다.
  /// - Parameters:
  ///   - router: ``Router``의 구현체
  ///   - requestType: ``RequestType`` 값, 기본값은 ``RequestType/remote`` 입니다.
  /// - Returns: 요청 결과 데이터
  public func request(_ router: T, requestType: RequestType = .remote) async throws -> Data {
    switch requestType {
    case .remote:
      return try await sendRequest(router: router)
    case .cache:
      return try await cacheRequest(router: router)
    case .stub, .delayedStub:
      return try await stubRequest(router: router, requestType: requestType)
    }
  }
}

/// RouterManager 내부 확장
///
/// request Type에 따른 요청 함수가 정의되어 있습니다.
fileprivate extension RouterManager {
  /// 요청을 보냅니다.
  /// - Parameters:
  ///   - router: 라우터
  ///   - retryCount: 재시도 횟수
  /// - Returns: 요청 결과 데이터
  private func sendRequest(router: T, retryCount: Int = 0) async throws -> Data {
    let urlRequest: URLRequest

    do {
      urlRequest = try await createURLRequest(router: router)
    } catch {
      throw RouterManagerErrorFactory.failedCreateURLRequest(error)
    }

    var cacheContainer: CacheContainer? = nil
    
    if let url = urlRequest.url, router.method.isEnableEtag {
      do {
        cacheContainer = try await fetchCache(
          for: url,
          enableDiskCache: router.method.isEnableDiskCache
        )
      } catch {
        Logger.log("E-Tag가 활성화되어 있지만 저장된 캐시 조회에 실패했습니다. 첫번째 요청인 경우 이 문제가 발생할 수 있습니다.", error)
      }
    }

    do {
      let response = try await requestWithCache(
        urlRequest: urlRequest,
        isEnableEtag: router.method.isEnableEtag,
        isEnableDiskCache: router.method.isEnableDiskCache,
        cacheContainer: cacheContainer
      )

      return response
    } catch {
      if await retrier.retry(router: router, dueTo: error, retryCount: retryCount) {
        return try await sendRequest(router: router, retryCount: retryCount + 1)
      }

      throw error
    }
  }
  
  /// stub을 반환합니다.
  /// - Parameters:
  ///   - router: 라우터
  ///   - requestType: 요청 타입
  /// - Returns: stub 데이터
  private func stubRequest(router: T, requestType: RequestType) async throws -> Data {
    switch requestType {
    case .remote, .cache:
      throw RouterManagerErrorFactory.requestTypeError()
    case .stub:
      return router.sampleData
    case let .delayedStub(delay):
      try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
      return router.sampleData
    }
  }

  /// 캐시를 요청합니다.
  /// - Note: 디스크 캐시는 메모리 캐시가 없을 경우에만 확인합니다. (우선순위: 메모리 캐시 -> 디스크 캐시)
  /// 디스크 캐시에서 캐시가 조회되면, 메모리 캐시에 저장합니다.
  /// - Parameters:
  ///   - router: 라우터
  /// - Returns: 캐시된 데이터
  /// - Throws: 캐시 조회 실패 시. (캐시가 없을 경우.)
  private func cacheRequest(router: T) async throws -> Data {
    let urlRequest = try await createURLRequest(router: router)
    
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

/// RouterManager 내부 확장
/// NOTE: 캐시 관련 함수 및 내부에서 사용되는 함수가 정의되어 있습니다.
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
  ///   - cacheContainer: 캐시 컨테이너
  /// - Returns: 요청 결과 데이터
  private func requestWithCache(
    urlRequest: URLRequest,
    isEnableEtag: Bool,
    isEnableDiskCache: Bool,
    cacheContainer: CacheContainer?
  ) async throws -> Data {
    var urlRequest = urlRequest
    
    if let etag = cacheContainer?.etag, isEnableEtag {
      urlRequest.setValue(etag, forHTTPHeaderField: "If-None-Match")
    }
    
    let data: Data
    var response: URLResponse? = nil
    
    do {
      networkEventMonitor?.requestDidStart(urlRequest)
      (data, response) = try await URLSession.shared.data(for: urlRequest)
      networkEventMonitor?.requestDidFinish(urlRequest, response, data)
    } catch {
      throw RouterManagerErrorFactory.requestError(response: response, error)
    }
    
    guard let httpResponse = response as? HTTPURLResponse else {
      throw RouterManagerErrorFactory.urlResponseIsNil()
    }
    
    if let cacheContainer = cacheContainer {
      if 304 == httpResponse.statusCode {
        return cacheContainer.data
      }
    }
    
    if (200 ..< 300) ~= httpResponse.statusCode {
      guard let url = urlRequest.url else {
        throw RouterManagerErrorFactory.urlIsNil()
      }
      
      if isEnableEtag {
        let etag = httpResponse.allHeaderFields["Etag"] as? String
        await saveCache(
          for: url,
          enableDiskCache: isEnableDiskCache,
          cacheContainer: .init(data: data, etag: etag)
        )
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
  ///   - cacheContainer: 캐시 컨테이너
  private func saveCache(
    for url: URL,
    enableDiskCache: Bool,
    cacheContainer: CacheContainer
  ) async {
    do {
      try await memoryCacheLoader.save(for: url.absoluteString, cacheContainer)
    } catch {
      Logger.log("E-Tag가 활성화 되어 있지만, 메모리 캐시 저장에 실패했습니다.", error)
    }
    
    if enableDiskCache {
      do {
        try await diskCacheLoader.save(for: url.absoluteString, cacheContainer)
      } catch {
        Logger.log("E-Tag와 DiskCache가 활성화 되어 있지만, 디스크 캐시 저장에 실패했습니다.", error)
      }
    }
  }
  
  /// URLRequest를 생성합니다.
  /// - Parameters:
  ///   - router: 라우터
  /// - Returns: URL 요청
  private func createURLRequest(router: T) async throws -> URLRequest {
    var urlRequest = {
      var urlRequest = URLRequest(url: router.path.isEmpty ? router.baseURL : router.baseURL.appendingPathComponent(router.path))
      urlRequest.httpMethod = router.method.rawValue
      urlRequest.allHTTPHeaderFields = router.headers
      if router.method.isEnableEtag {
        urlRequest.cachePolicy = .reloadIgnoringLocalCacheData
      }
      return urlRequest
    }()
    
    switch router.task {
    case .requestPlain:
      urlRequest.httpBody = nil
      
    case let .requestJSONEncodable(encodable):
      urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
      urlRequest.httpBody = try JSONEncoder().encode(encodable)

    case let .requestCustomJSONEncodable(encodable, encoder):
      urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
      urlRequest.httpBody = try encoder.encode(encodable)
      
    case let .requestParameters(parameters, type):
      switch type {
      case .body:
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])

      case .query:
      if case .post = router.method {
          // POST 요청의 경우 x-www-form-urlencoded 로 전송합니다.
          let formBody = parameters.map { key, value in
            let encodedKey = "\(key)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "\(key)"
            let encodedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "\(value)"
            return "\(encodedKey)=\(encodedValue)"
          }.joined(separator: "&")
          
          urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
          urlRequest.httpBody = formBody.data(using: .utf8)
        } else {
        var components = URLComponents(url: router.path.isEmpty ? router.baseURL : router.baseURL.appendingPathComponent(router.path), resolvingAgainstBaseURL: false)
          components?.queryItems = parameters.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
          guard let url = components?.url else { throw RouterManagerErrorFactory.urlIsNil() }
          urlRequest.url = url
        }
      }

    case let .multipartFormData(boundary, parts):
      let boundary = boundary ?? UUID().uuidString

      urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

      var body = Data()
      
      for part in parts {
        body.append("--\(boundary)\r\n".data(using: .utf8)!)

        var contentDisposition = "Content-Disposition: form-data; name=\"\(part.name)\""
        if let fileName = part.fileName {
          contentDisposition += "; filename=\"\(fileName)\""
        }
        body.append("\(contentDisposition)\r\n".data(using: .utf8)!)

        body.append("Content-Type: \(part.mimeType)\r\n\r\n".data(using: .utf8)!)

        body.append(part.data)

        body.append("\r\n".data(using: .utf8)!)
      }

      body.append("--\(boundary)--\r\n".data(using: .utf8)!)

      urlRequest.httpBody = body
    }
    
    do {
      urlRequest = try await interceptor.intercept(urlRequest)
    } catch {
      throw RouterManagerErrorFactory.interceptorError(error)
    }
    
    return urlRequest
  }
}
