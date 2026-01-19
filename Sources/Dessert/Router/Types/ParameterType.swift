
import Foundation

/// 파라미터 타입
///
/// ``RouterTask/requestParameters(parameters:type:)`` 의 인자로 사용됩니다.
public enum ParameterType: Sendable {
  /// body에 json 형식으로 전달합니다.
  case body
  /// URL에 쿼리 파라미터로 전달합니다.
  case query
}
