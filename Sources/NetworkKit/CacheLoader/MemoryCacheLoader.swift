
import Foundation

extension MemoryCacheLoader {
  internal static let shared = MemoryCacheLoader()
}

internal final class MemoryCacheLoader: CacheLoader {
  private let cache: NSCache<NSString, NSData>
  private let queue: DispatchQueue

  internal init(
    cache: NSCache<NSString, NSData> = NSCache<NSString, NSData>(),
    queue: DispatchQueue = DispatchQueue(label: "com.NetworkKit.MemoryCacheLoader")
  ) {
    self.cache = cache
    self.queue = queue
  }

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

  internal func clear() async throws {
    return try await withCheckedThrowingContinuation { continuation in
      queue.async {
        self.cache.removeAllObjects()
        continuation.resume(returning: ())
      }
    }
  }
}
