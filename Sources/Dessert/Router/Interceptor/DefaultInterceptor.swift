
import Foundation

/// 기본 ``Interceptor`` 입니다.
///
/// 기본 ``Interceptor``는 URLRequest 를 변형하지 않도록 구현되어 있습니다.
public struct DefaultInterceptor: Interceptor {
  /// ``DefaultInterceptor`` 인스턴스를 생성합니다.
  public init() {}

  /// intercept 메서드를 구현합니다.
  /// - Parameters:
  ///   - request: 기존  URLRequest 입니다.
  /// - Returns: 변형된 URLRequest 입니다.
  ///
  /// 해당 인터셉터에서는 URLRequest 를 변형하지 않도록 구현되어 있습니다.
  public func intercept(_ request: URLRequest) async throws -> URLRequest {
    return request
  }
}
