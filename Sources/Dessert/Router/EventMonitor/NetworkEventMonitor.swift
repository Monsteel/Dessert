
import Foundation

/// 네트워크 이벤트 모니터
///
/// 네트워크 이벤트를 관찰할 수 있습니다.
///
/// 해당 프로토콜을 구현하고, ``RouterManager`` 생성 시 인자로 전달하여 사용합니다.
public protocol NetworkEventMonitor: Sendable {
  /// URLSession 을 통한 요청 직전에 호출됩니다.
  /// - Parameter request: 실제 호출에 사용된 최종 요청정보 입니다.
  func requestDidStart(_ request: URLRequest)
  /// URLSession 을 통한 요청 직후에 호출됩니다.
  /// - Parameters:
  ///   - request: 실제 호출에 사용된 최종 요청정보 입니다.
  ///   - response: 호출 결과 응답정보 입니다.
  ///   - data: 호출 결과 응답 데이터 입니다.
  func requestDidFinish(_ request: URLRequest, _ response: URLResponse?, _ data: Data?)
}
