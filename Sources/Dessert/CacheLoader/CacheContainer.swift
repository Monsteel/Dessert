
import Foundation

/// 캐시 컨테이너
/// Note: 캐시 컨테이너는 캐시 데이터와 ETag를 포함합니다.
internal struct CacheContainer: Codable {
  /// 캐시 데이터
  let data: Data
  /// ETag
  let etag: String?
}
