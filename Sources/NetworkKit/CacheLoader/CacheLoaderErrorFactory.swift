
import Foundation

internal enum CacheLoaderErrorFactory {
  private enum Code: Int {
    case invalidURL = 0
    case failedToSaveDiskCache = 1
    case unknown = 2
    case failedToDecode = 3
    case failedToEncode = 4
    case failedToClearDiskCache = 5
    case diskCacheNotFound = 7
    case memoryCacheNotFound = 8
  }

  internal static func invalidURL(_ url: String) -> NSError {
    NSError(
      domain: "\(Self.self)",
      code: Code.invalidURL.rawValue,
      userInfo: [
        "url": url
      ]
    )
  }
  
  internal static func failedToSaveDiskCache(_ result: Bool) -> NSError {
    NSError(
      domain: "\(Self.self)",
      code: Code.failedToSaveDiskCache.rawValue,
      userInfo: [
        "result": result
      ]
    )
  }

  internal static func unknown(_ underlying: Error) -> NSError {
    NSError(
      domain: "\(Self.self)",
      code: Code.unknown.rawValue,
      userInfo: [
        NSUnderlyingErrorKey: underlying
      ]
    )
  }

  internal static func failedToDecode(_ underlying: Error) -> NSError {
    NSError(
      domain: "\(Self.self)",
      code: Code.failedToDecode.rawValue,
      userInfo: [
        NSUnderlyingErrorKey: underlying
      ]
    )
  }

  internal static func failedToEncode(_ underlying: Error) -> NSError {
    NSError(
      domain: "\(Self.self)",
      code: Code.failedToEncode.rawValue,
      userInfo: [
        NSUnderlyingErrorKey: underlying
      ]
    )
  }

  internal static func failedToClearDiskCache(_ underlying: Error) -> NSError {
    NSError(
      domain: "\(Self.self)",
      code: Code.failedToClearDiskCache.rawValue,
      userInfo: [
        NSUnderlyingErrorKey: underlying
      ]
    )
  }

  internal static func diskCacheNotFound(_ localCachePath: String) -> NSError {
    NSError(
      domain: "\(Self.self)",
      code: Code.diskCacheNotFound.rawValue,
      userInfo: ["localCachePath": localCachePath]
    )
  }

  internal static func memoryCacheNotFound(_ key: String) -> NSError {
    NSError(
      domain: "\(Self.self)",
      code: Code.memoryCacheNotFound.rawValue,
      userInfo: ["key": key]
    )
  }
}
