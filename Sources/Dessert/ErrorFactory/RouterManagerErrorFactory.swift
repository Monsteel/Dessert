
import Foundation

/// 라우터 매니저 에러 팩토리
public enum RouterManagerErrorFactory {
  /// 라우터 매니저 에러 코드
  public enum Code: Int {
    /// 요청 타입 에러 : 0
    case requestTypeError = 0
    /// URLRequest 생성 실패 에러 : 1
    case failedCreateURLRequest = 1
    /// 응답 데이터가 nil 인 경우 에러 : 2
    case responseDataIsNil = 2
    /// 응답 정보가 nil 인 경우 에러 : 3
    case urlResponseIsNil = 3
    /// 응답 상태 코드가 200 번대가 아닌 경우 에러 : 4
    case badResponse = 4
    /// URL 이 nil 인 경우 에러 : 5
    case urlIsNil = 5
    /// 요청 에러 : 6
    case requestError = 6
    /// 인터셉터 에러 : 7
    case interceptorError = 7
  }

  /// 요청 타입 에러
  /// - Returns: 요청 타입 에러
  internal static func requestTypeError() -> NSError {
    NSError(
      domain: "\(Self.self)",
      code: Code.requestTypeError.rawValue,
      userInfo: nil
    )
  }

  /// URLRequest 생성 실패 에러
  /// - Parameters:
  ///   - underlying: 기원 에러
  /// - Returns: URLRequest 생성 실패 에러  
  internal static func failedCreateURLRequest(_ underlying: Error) -> NSError {
    NSError(
      domain: "\(Self.self)",
      code: Code.failedCreateURLRequest.rawValue,
      userInfo: [
        NSUnderlyingErrorKey: underlying
      ]
    )
  }

  /// 응답 데이터가 nil 인 경우 에러
  /// - Returns: 응답 데이터가 nil 인 경우 에러
  internal static func responseDataIsNil() -> NSError {
    NSError(
      domain: "\(Self.self)",
      code: Code.responseDataIsNil.rawValue,
      userInfo: nil
    )
  }

  /// 응답 정보가 nil 인 경우 에러
  /// - Returns: 응답 정보가 nil 인 경우 에러
  internal static func urlResponseIsNil() -> NSError {
    NSError(
      domain: "\(Self.self)",
      code: Code.urlResponseIsNil.rawValue,
      userInfo: nil
    )
  }

  /// 응답 상태 코드가 200 번대가 아닌 경우 에러
  /// - Parameters:
  ///   - response: 응답 정보
  /// - Returns: 응답 상태 코드가 200 번대가 아닌 경우 에러
  internal static func badResponse(_ response: HTTPURLResponse) -> NSError {
    NSError(
      domain: "\(Self.self)",
      code: Code.badResponse.rawValue,
      userInfo: nil
    )
  }

  /// URL 이 nil 인 경우 에러
  /// - Returns: URL 이 nil 인 경우 에러
  internal static func urlIsNil() -> NSError {
    NSError(
      domain: "\(Self.self)",
      code: Code.urlIsNil.rawValue,
      userInfo: nil
    )
  }

  /// 요청 에러
  /// - Parameters:
  ///   - response: 응답 정보
  ///   - underlying: 기원 에러
  /// - Returns: 요청 에러
  internal static func requestError(response: URLResponse?, _ underlying: Error) -> NSError {
    let response = response as? HTTPURLResponse
    let userInfo: [String: Any] = {
      if let response = response {
        return [
          NSUnderlyingErrorKey: underlying,
          "response": response
        ]
      }
      return [NSUnderlyingErrorKey: underlying]
    }()

    return NSError(
      domain: "\(Self.self)",
      code: Code.requestError.rawValue,
      userInfo: userInfo
    )
  }

  /// 인터셉터 에러
  /// - Parameters:
  ///   - underlying: 기원 에러
  /// - Returns: 인터셉터 에러
  internal static func interceptorError(_ underlying: Error) -> NSError {
    NSError(
      domain: "\(Self.self)",
      code: Code.interceptorError.rawValue,
      userInfo: [
        NSUnderlyingErrorKey: underlying
      ]
    )
  }
}
