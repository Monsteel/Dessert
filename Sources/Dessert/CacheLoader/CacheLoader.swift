
import Foundation

/// 캐시 로더
/// Note: 캐시 로더는 캐시를 저장하고 가져오는 기능을 제공합니다.
internal protocol CacheLoader {
  /// 캐시를 저장합니다.
  /// - Parameters:
  ///   - key: 키
  ///   - value: 캐시 컨테이너
  func save(for key: String, _ value: CacheContainer) async throws
  /// 캐시를 가져옵니다.
  /// - Parameters:
  ///   - key: 키
  /// - Returns: 캐시 컨테이너
  func get(for key: String) async throws -> CacheContainer
  /// 캐시를 삭제합니다.
  func clear() async throws
}
