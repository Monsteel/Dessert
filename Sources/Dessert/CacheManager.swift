
import Foundation

extension CacheManager {
  /// 접근 가능한 인스턴스
  ///
  /// 해당 인스턴스를 통해 메모리 캐시와 디스크 캐시에 접근할 수 있습니다.
  public static let shared = CacheManager()
}

/// 캐시 매니저
///
/// 메모리 캐시와 디스크 캐시에 접근할 수 있습니다.
///
/// ``CacheManager/shared`` 를 통해 접근하여야 하며, 직접적으로 캐시에 접근하는 것은 불가능합니다.
public final class CacheManager {
  /// 메모리 캐시 로더
  private let memoryCacheLoader: MemoryCacheLoader
  /// 디스크 캐시 로더
  private let diskCacheLoader: DiskCacheLoader

  /// CacheManager를 생성합니다.
  /// - Parameters:
  ///   - memoryCacheLoader: 메모리 캐시 로더
  ///   - diskCacheLoader: 디스크 캐시 로더
  private init(
    memoryCacheLoader: MemoryCacheLoader = .shared,
    diskCacheLoader: DiskCacheLoader = .shared
  ) {
    self.memoryCacheLoader = memoryCacheLoader
    self.diskCacheLoader = diskCacheLoader
  }

  /// 메모리 캐시와 디스크 캐시를 초기화합니다.
  ///
  /// 초기화 외 다른 접근은 불가능합니다.
  public func clear() async throws {
    try await withThrowingTaskGroup(of: Void.self) { group in
      group.addTask {
        try await self.memoryCacheLoader.clear()
      }
      group.addTask {
        try await self.diskCacheLoader.clear()
      }
      try await group.waitForAll()
    }
  }
}
