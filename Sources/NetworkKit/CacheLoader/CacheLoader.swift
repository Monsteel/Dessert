
import Foundation

internal protocol CacheLoader {
  func save(for key: String, _ value: CacheContainer) async throws
  func get(for key: String) async throws -> CacheContainer
  func clear() async throws
}
