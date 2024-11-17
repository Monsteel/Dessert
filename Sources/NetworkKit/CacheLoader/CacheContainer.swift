
import Foundation

internal struct CacheContainer: Codable {
  let data: Data
  let etag: String?
}
