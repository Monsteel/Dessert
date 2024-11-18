
import Foundation

/// 캐시 로더 에러 팩토리
public enum CacheLoaderErrorFactory {
  /// 캐시 로더 에러 코드
  public enum Code: Int {
    /// 유효하지 않은 URL 에러 : 0
    case invalidURL = 0
    /// 디스크 캐시 저장 실패 에러 : 1
    case failedToSaveDiskCache = 1
    /// 알 수 없는 에러 : 2
    case unknown = 2
    /// 디코딩 실패 에러 : 3
    case failedToDecode = 3
    /// 인코딩 실패 에러 : 4
    case failedToEncode = 4
    /// 디스크 캐시 삭제 실패 에러 : 5
    case failedToClearDiskCache = 5
    /// 디스크 캐시 없음 에러 : 6
    case diskCacheNotFound = 6
    /// 메모리 캐시 없음 에러 : 7
    case memoryCacheNotFound = 7
  }

  /// 유효하지 않은 URL 에러
  /// - Parameters:
  ///   - url: URL
  /// - Returns: 유효하지 않은 URL 에러
  internal static func invalidURL(_ url: String) -> NSError {
    NSError(
      domain: "\(Self.self)",
      code: Code.invalidURL.rawValue,
      userInfo: [
        "url": url
      ]
    )
  }

  /// 디스크 캐시 저장 실패 에러
  /// - Parameters:
  ///   - result: 저장 결과
  /// - Returns: 디스크 캐시 저장 실패 에러
  internal static func failedToSaveDiskCache(_ result: Bool) -> NSError {
    NSError(
      domain: "\(Self.self)",
      code: Code.failedToSaveDiskCache.rawValue,
      userInfo: [
        "result": result
      ]
    )
  }

  /// 알 수 없는 에러
  /// - Parameters:
  ///   - underlying: 기원 에러
  /// - Returns: 알 수 없는 에러
  internal static func unknown(_ underlying: Error) -> NSError {
    NSError(
      domain: "\(Self.self)",
      code: Code.unknown.rawValue,
      userInfo: [
        NSUnderlyingErrorKey: underlying
      ]
    )
  }

  /// 디코딩 실패 에러
  /// - Parameters:
  ///   - underlying: 기원 에러
  /// - Returns: 디코딩 실패 에러
  internal static func failedToDecode(_ underlying: Error) -> NSError {
    NSError(
      domain: "\(Self.self)",
      code: Code.failedToDecode.rawValue,
      userInfo: [
        NSUnderlyingErrorKey: underlying
      ]
    )
  }

  /// 인코딩 실패 에러
  /// - Parameters:
  ///   - underlying: 기원 에러
  /// - Returns: 인코딩 실패 에러
  internal static func failedToEncode(_ underlying: Error) -> NSError {
    NSError(
      domain: "\(Self.self)",
      code: Code.failedToEncode.rawValue,
      userInfo: [
        NSUnderlyingErrorKey: underlying
      ]
    )
  }

  /// 디스크 캐시 삭제 실패 에러
  /// - Parameters:
  ///   - underlying: 기원 에러
  /// - Returns: 디스크 캐시 삭제 실패 에러
  internal static func failedToClearDiskCache(_ underlying: Error) -> NSError {
    NSError(
      domain: "\(Self.self)",
      code: Code.failedToClearDiskCache.rawValue,
      userInfo: [
        NSUnderlyingErrorKey: underlying
      ]
    )
  }

  /// 디스크 캐시 없음 에러
  /// - Parameters:
  ///   - localCachePath: 로컬 캐시 경로
  /// - Returns: 디스크 캐시 없음 에러
  internal static func diskCacheNotFound(_ localCachePath: String) -> NSError {
    NSError(
      domain: "\(Self.self)",
      code: Code.diskCacheNotFound.rawValue,
      userInfo: ["localCachePath": localCachePath]
    )
  }

  /// 메모리 캐시 없음 에러
  /// - Parameters:
  ///   - key: 키
  /// - Returns: 메모리 캐시 없음 에러
  internal static func memoryCacheNotFound(_ key: String) -> NSError {
    NSError(
      domain: "\(Self.self)",
      code: Code.memoryCacheNotFound.rawValue,
      userInfo: ["key": key]
    )
  }
}
