
import Foundation

/// 기본 ``Retrier`` 입니다.
///
/// 기본 ``Retrier``는 항상 재시도를 수행하지 않도록 구현되어 있습니다.
public actor DefaultRetrier: Retrier {
  /// ``DefaultRetrier`` 인스턴스를 생성합니다.
  public init() {}

  /// retry 메서드를 구현합니다.
  /// - Parameters:
  ///   - router: 라우터
  ///   - error: 에러
  ///   - retryCount: 재시도 횟수
  /// - Returns: 재시도 여부
  ///
  /// 해당 ``Retrier``는 항상 재시도를 수행하지 않도록 구현되어 있습니다.
  public func retry(router: Router, dueTo error: Error, retryCount: Int) async -> Bool {
    return false
  }
}
