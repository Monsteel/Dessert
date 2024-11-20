
import Foundation

/// 이 Protocol을 채택하여, 라우터를 구현합니다.
public protocol Router: Hashable {
  /// 기본 URL
  var baseURL: URL { get }
  /// 경로
  var path: String { get }
  /// HTTP 메서드
  var method: HttpMethod { get }
  /// 샘플 데이터
  var sampleData: Data { get }
  /// 작업
  var task: RouterTask { get }
  /// 헤더
  var headers: [String: String]? { get }
}

public extension Router {
  /// `stub` 데이터가 테스팅에 사용될 때, 기본 데이터는 `Data()` 입니다.
  var sampleData: Data { .init() }
}

public enum RouterTask {
  /// 추가적인 데이터 없는 Request
  ///
  /// 네트워크 요청 시, 추가적인 데이터가 필요하지 않은 경우 사용합니다.
  case requestPlain

  /// Encodable 타입의 Body를 설정한 Request
  /// - Parameters:
  ///   - encodable: Encodable 타입의 Body
  ///
  /// 네트워크 요청 시, Body에 JSON 형식으로 전달됩니다.
  case requestJSONEncodable(Encodable)

  /// Encodable 타입의 Body와 custom encoder를 설정한 Request
  /// - Parameters:
  ///   - encodable: Encodable 타입의 Body
  ///   - encoder: custom encoder
  ///
  /// 네트워크 요청 시, Body에 JSON 형식으로 전달됩니다.
  case requestCustomJSONEncodable(Encodable, encoder: JSONEncoder = .init())

  /// encode 된 parameter를 설정한 Request
  /// - Parameters:
  ///   - parameters: encode 된 parameter
  ///   - type: 파라미터 타입, 기본 타입은 `body` 입니다.
  ///
  /// 파라미터 타입에 따라, Body에 전달되거나 URL에 쿼리 파라미터로 전달됩니다.
  case requestParameters(parameters: [String: Any], type: ParameterType = .body)

  /// multipart/form-data 형식의 데이터를 설정한 Request  
  /// - Parameters:
  ///   - boundary: multipart/form-data의 boundary 입니다. nil일 경우 자동으로 생성됩니다.
  ///   - parts: multipart/form-data의 part 요소
  case multipartFormData(boundary: String? = nil, parts: [MultipartFormDataPart])
}
