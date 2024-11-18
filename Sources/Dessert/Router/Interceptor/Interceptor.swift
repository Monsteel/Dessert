
import Foundation

/// 호출 직전 URLRequest 를 변형하는 기능을 제공합니다.
///
/// 해당 프로토콜을 구현하고, ``RouterManager`` 생성 시 인자로 전달하여 사용합니다.
public protocol Interceptor {
  /// 요청을 변형하고자 하는 경우 구현하여 URLRequest 를 반환합니다.
  /// - Parameters:
  ///   - request: 기존 URLRequest 입니다.
  /// - Returns: 변형된 URLRequest 입니다.
  func intercept(_ request: URLRequest) async throws -> URLRequest
}
