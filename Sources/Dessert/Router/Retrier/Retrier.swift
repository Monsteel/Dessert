
import Foundation

/// 오류 발생 시 재시도 수행 여부를 결정합니다.
///
/// 해당 protocol을 구현하여 RouterManager에 등록하여 사용합니다.
public protocol Retrier {
  /// 재시도 여부를 결정하여 반환합니다.
  /// - Parameters:
  ///   - router: 라우터
  ///   - error: 에러
  ///   - retryCount: 재시도 횟수
  /// - Returns: 재시도 여부
  func retry(router: Router, dueTo error: Error, retryCount: Int) async -> Bool
}
