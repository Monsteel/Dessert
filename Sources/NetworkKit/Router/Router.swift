
import Foundation

public protocol Router {
  var baseURL: URL { get }
  var path: String { get }
  var method: HttpMethod { get }
  var sampleData: Data { get }
  var task: RouterTask { get }
  var headers: [String: String]? { get }
}

public extension Router {
  /// `stub` 데이터가 테스팅에 사용될 때, 기본 데이터는 `Data()` 입니다.
  var sampleData: Data { .init() }
}

public enum RouterTask {
  /// 추가적인 데이터 없는 Request
  case requestPlain
  
  /// Encodable 타입의 Body를 설정한 Request
  /// - Parameters:
  ///   - encodable: Encodable 타입의 Body
  case requestJSONEncodable(Encodable)
  
  /// Encodable 타입의 Body와 custom encoder를 설정한 Request
  /// - Parameters:
  ///   - encodable: Encodable 타입의 Body
  ///   - encoder: custom encoder
  case requestCustomJSONEncodable(Encodable, encoder: JSONEncoder)
  
  /// encode 된 parameter를 설정한 Request
  /// - Parameters:
  ///   - parameters: encode 된 parameter
  ///   - type: 파라미터 타입, 기본 타입은 `body` 입니다.
  case requestParameters(parameters: [String: Any], type: ParameterType = .body)
}
