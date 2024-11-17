
import Foundation

public enum HttpMethod {
  case get(enableEtag: Bool = false, enableDiskCache: Bool = true)
  case post
  case put
  case delete
}

extension HttpMethod {
  internal var rawValue: String {
    switch self {
      case .get: return "GET"
      case .post: return "POST"
      case .put: return "PUT"
      case .delete: return "DELETE"
    }
  }

  internal var isEnableEtag: Bool {
    if case let .get(enableEtag, _) = self, enableEtag {
      return true
    }
    return false
  }

  internal var isEnableDiskCache: Bool {
    if case let .get(enableEtag, enableDiskCache) = self, enableEtag, enableDiskCache {
      return true
    }
    return false
  }
}
