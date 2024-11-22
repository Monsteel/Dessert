
import Foundation

extension DiskCacheLoader {
  /// 기본 디스크 캐시 로더
  /// Note: 기본 디스크 캐시 로더입니다.
  public static let `default` = DiskCacheLoader()
}

/// 디스크 캐시 로더
/// Note: 디스크 캐시를 저장하고 가져오는 기능을 제공합니다.
public final class DiskCacheLoader: CacheLoader {
  /// 파일 매니저
  private let fm: FileManager
  /// 디스패치 큐
  private let queue: DispatchQueue
  /// 경로
  private let path: String

  /// initializer
  /// - Parameters:
  ///   - fm: 파일 매니저
  ///   - queue: 디스패치 큐
  ///   - path: 경로 (Dessert 하위 경로로 지정 됩니다.)
  public init(
    fm: FileManager = .default,
    queue: DispatchQueue = DispatchQueue(label: "com.Dessert.DiskCacheLoader"),
    path: String = ""
  ) {
    self.fm = fm
    self.queue = queue
    self.path = path
  }

  /// 캐시를 저장합니다.
  /// - Parameters:
  ///   - key: 키
  ///   - value: 캐시 컨테이너
  internal func save(for key: String, _ value: CacheContainer) async throws {
    return try await withCheckedThrowingContinuation { continuation in
      queue.async {
        do {
          // Convert key to URL
          guard let remoteURL = URL(string: key) else {
            return continuation.resume(throwing: CacheLoaderErrorFactory.invalidURL(key))
          }
          
          // If the directory does not exits, create it
          if self.fm.fileExists(atPath: self.diskCachePath.path) == false {
            try self.fm.createDirectory(at: self.diskCachePath, withIntermediateDirectories: true, attributes: nil)
          }
          
          // Get local disk cache path
          let localCachePath = self.diskCacheLocalURL(remoteURL).path
          
          // If the file exists, remove it
          if self.fm.fileExists(atPath: localCachePath) {
            try self.fm.removeItem(atPath: localCachePath)
          }
          
          // Convert value to data
          let data: Data
          do {
            data = try JSONEncoder().encode(value)
          } catch {
            return continuation.resume(throwing: CacheLoaderErrorFactory.failedToEncode(error))
          }
          
          // Save data to local cache path
          let result = self.fm.createFile(atPath: localCachePath, contents: data, attributes: nil)
          
          // Resume the continuation
          if result {
            return continuation.resume(returning: Void())
          } else {
            return continuation.resume(throwing: CacheLoaderErrorFactory.failedToSaveDiskCache(result))
          }
        } catch {
          return continuation.resume(throwing: CacheLoaderErrorFactory.unknown(error))
        }
      }
    }
  }

  /// 캐시를 가져옵니다.
  /// - Parameters:
  ///   - key: 키
  /// - Returns: 캐시 컨테이너
  internal func get(for key: String) async throws -> CacheContainer {
    return try await withCheckedThrowingContinuation { continuation in
      queue.async {
        // Convert key to URL
        guard let remoteURL = URL(string: key) else {
          return continuation.resume(throwing: CacheLoaderErrorFactory.invalidURL(key))
        }

        // Get local disk cache path
        let localCachePath = self.diskCacheLocalURL(remoteURL).path

        // Get data from local disk cache path
        guard let data = self.fm.contents(atPath: localCachePath) else {
          return continuation.resume(throwing: CacheLoaderErrorFactory.diskCacheNotFound(localCachePath))
        }

        do {
          // Convert data to CacheContainer
          let value = try JSONDecoder().decode(CacheContainer.self, from: data)
          return continuation.resume(returning: value)
        } catch {
          return continuation.resume(throwing: CacheLoaderErrorFactory.failedToDecode(error))
        }
      }
    }
  }

  /// 디스크 캐시 경로
  private var diskCachePath: URL {
    let documentDirectoryPath = NSSearchPathForDirectoriesInDomains(
      .cachesDirectory,
      .userDomainMask,
      true
    )[0] as NSString

    let diskCachePath = documentDirectoryPath.appendingPathComponent("Dessert/\(path)")

    return URL(fileURLWithPath: diskCachePath)
  }

  /// 디스크 캐시 로컬 URL
  /// - Parameters:
  ///   - remoteURL: 원격 URL
  /// - Returns: 디스크 캐시 로컬 URL
  private func diskCacheLocalURL(_ remoteURL: URL) -> URL {
    // URL encode the entire remote URL string
    let encodedFilename = remoteURL.absoluteString
      .addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? remoteURL.lastPathComponent
    
    return diskCachePath
      .appendingPathComponent(encodedFilename)
      .appendingPathExtension("json")
  }

  /// 디스크 캐시를 삭제합니다.
  internal func clear() async throws {
    return try await withCheckedThrowingContinuation { continuation in
      queue.async {
        do {
          try self.fm.removeItem(at: self.diskCachePath)
          return continuation.resume(returning: Void())
        } catch {
          return continuation.resume(throwing: CacheLoaderErrorFactory.failedToClearDiskCache(error))
        }
      }
    }
  }
}
