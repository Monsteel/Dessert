
import Foundation

/// HTTP 메서드
public enum HttpMethod: Sendable {
  /// GET 메서드
  /// - Parameters:
  ///   - enableEtag: ETag 활성화 여부
  ///   - enableDiskCache: 디스크 캐시 활성화 여부
  case get(enableEtag: Bool = false, enableDiskCache: Bool = true)
  /// POST 메서드
  case post
  /// PUT 메서드
  case put
  /// DELETE 메서드
  case delete
}

extension HttpMethod {
  /// HTTP 메서드 문자열
  internal var rawValue: String {
    switch self {
      case .get: return "GET"
      case .post: return "POST"
      case .put: return "PUT"
      case .delete: return "DELETE"
    }
  }

  /// ETag 활성화 여부
  /// Note: ETag는 GET 메서드에만 적용됩니다.
  internal var isEnableEtag: Bool {
    if case let .get(enableEtag, _) = self, enableEtag {
      return true
    }
    return false
  }

  /// 디스크 캐시 활성화 여부
  /// Note: 디스크 캐시는 GET 메서드에만 적용되며, E-Tag가 활성화되어 있어야 합니다.
  internal var isEnableDiskCache: Bool {
    if case let .get(enableEtag, enableDiskCache) = self, enableEtag, enableDiskCache {
      return true
    }
    return false
  }
}
