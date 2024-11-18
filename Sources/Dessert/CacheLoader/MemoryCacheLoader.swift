
import Foundation

extension MemoryCacheLoader {
  /// 공유 인스턴스
  /// Note: 해당 인스턴스를 사용하여 메모리 캐시에 접근합니다.
  internal static let shared = MemoryCacheLoader()
}

/// 메모리 캐시 로더
/// Note: 메모리 캐시를 저장하고 가져오는 기능을 제공합니다.
internal final class MemoryCacheLoader: CacheLoader {
  /// 캐시
  private let cache: NSCache<NSString, NSData>
  /// 디스패치 큐
  private let queue: DispatchQueue

  /// initializer
  /// - Parameters:
  ///   - cache: 캐시
  ///   - queue: 디스패치 큐
  internal init(
    cache: NSCache<NSString, NSData> = NSCache<NSString, NSData>(),
    queue: DispatchQueue = DispatchQueue(label: "com.Dessert.MemoryCacheLoader")
  ) {
    self.cache = cache
    self.queue = queue
  }

  /// 캐시를 저장합니다.
  /// - Parameters:
  ///   - key: 키
  ///   - value: 캐시 컨테이너
  internal func save(for key: String, _ value: CacheContainer) async throws {
    return try await withCheckedThrowingContinuation { continuation in
      queue.async {
        do {
          let data = try JSONEncoder().encode(value)
          self.cache.setObject(NSData(data: data), forKey: NSString(string: key))
          continuation.resume(returning: ())
        } catch {
          continuation.resume(throwing: CacheLoaderErrorFactory.failedToEncode(error))
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
        if let data = self.cache.object(forKey: NSString(string: key)) as Data? {
          do {
            let value = try JSONDecoder().decode(CacheContainer.self, from: data)
            continuation.resume(returning: value)
          } catch {
            continuation.resume(throwing: CacheLoaderErrorFactory.failedToDecode(error))
          }
        } else {
          continuation.resume(throwing: CacheLoaderErrorFactory.memoryCacheNotFound(key))
        }
      }
    }
  }

  /// 캐시를 삭제합니다.
  internal func clear() async throws {
    return try await withCheckedThrowingContinuation { continuation in
      queue.async {
        self.cache.removeAllObjects()
        continuation.resume(returning: ())
      }
    }
  }
}
