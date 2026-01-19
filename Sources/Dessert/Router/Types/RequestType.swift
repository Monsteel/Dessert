
import Foundation

/// 요청 타입
///
/// ``RouterManager``의 request 함수의 인자로 사용됩니다.
public enum RequestType: Sendable {
  /// 네트워크를 통해 요청합니다.
  ///
  /// - Parameters:
  ///   - urlSession: URL SESSION
  ///
  /// 단, 캐시가 활성화되어 있으면, E-Tag에 따라 캐싱된 데이터가 반환됩니다.
  case remote(_ urlSession: URLSession)

  /// 캐시를 return합니다.
  ///
  /// 캐시가 없는 경우
  case cache

  /// stub을 return합니다.
  ///
  /// - Parameters:
  ///   - dataFactory: 반환할 Data factory
  ///
  /// 인자로 전달된 dataFactory의 return값 Data를 반환합니다.
  case stub(_ dataFactory: @Sendable (Router) -> Data)

  /// 딜레이 이후 stub을 return합니다.
  ///
  /// - Parameters:
  ///   - seconds: 딜레이 시간
  ///   - dataFactory: 반환할 Data factory
  ///
  /// 인자로 전달된 dataFactory의 return값 Data를 반환합니다.
  case delayedStub(seconds: TimeInterval, _ dataFactory: @Sendable (Router) -> Data)
}
