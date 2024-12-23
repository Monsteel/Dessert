
import Foundation

extension MemoryCacheLoader {
  /// 기본 메모리 캐시 로더
  /// Note: 기본 메모리 캐시 로더입니다.
  public static let `default` = MemoryCacheLoader()
}

/// 메모리 캐시 로더
/// Note: 메모리 캐시를 저장하고 가져오는 기능을 제공합니다.
public final class MemoryCacheLoader: CacheLoader {
  /// 캐시
  private let cache: NSCache<NSString, NSData>

  /// initializer
  /// - Parameters:
  ///   - cache: NSCache
  public init(
    cache: NSCache<NSString, NSData> = NSCache<NSString, NSData>()
  ) {
    self.cache = cache
  }

  /// 캐시를 저장합니다.
  /// - Parameters:
  ///   - key: 키
  ///   - value: 캐시 컨테이너
  internal func save(for key: String, _ value: CacheContainer) async throws {
    do {
      let data = try JSONEncoder().encode(value)
      self.cache.setObject(NSData(data: data), forKey: NSString(string: key))
    } catch {
      throw CacheLoaderErrorFactory.failedToEncode(error)
    }
  }

  /// 캐시를 가져옵니다.
  /// - Parameters:
  ///   - key: 키
  /// - Returns: 캐시 컨테이너
  internal func get(for key: String) async throws -> CacheContainer {
    guard let nsData = self.cache.object(forKey: NSString(string: key)) else {
      throw CacheLoaderErrorFactory.memoryCacheNotFound(key)
    }

    do {
      let data = Data(referencing: nsData)
      let value = try JSONDecoder().decode(CacheContainer.self, from: data)
      return value
    } catch {
      throw CacheLoaderErrorFactory.failedToDecode(error)
    }
  }

  /// 캐시를 삭제합니다.
  internal func clear() async throws {
    self.cache.removeAllObjects()
  }
}
