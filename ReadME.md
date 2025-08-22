# 🍰 Dessert

#### 🍰 달달한 Rest 네트워킹 모듈 인데, 이제 E-Tag를 곁들인.

💁🏻‍♂️ GET 요청 시, E-Tag를 사용하여 응답을 캐싱할 수 있습니다.<br>
💁🏻‍♂️ EventMonitor, Interceptor, Retirer기능을 제공합니다.<br>
💁🏻‍♂️ Router 구현을 통해, 가독성 높게 API를 열거하여 사용할 수 있습니다.<br>

## 장점

✅ E-Tag를 기반으로 캐싱되어, 데이터가 변경된 경우에만 네트워크 요청을 받습니다.<br>
✅ E-Tag 캐싱 사용을 활성화하면 메모리 캐싱은 기본적으로 제공되며, 설정을 통해 디스크 캐싱도 사용 가능합니다.<br>

## 사용방법

### [Router](https://github.com/Monsteel/Dessert/blob/main/Sources/Dessert/Router/Types/Router.swift)구현하기<br>

아래처럼 라우터를 구현할 수 있습니다.

```swift
import Dessert
import Foundation
import Model

public enum ExampleAPI {
  case fetchData
  case createPost(title: String, content: String)
  case updatePost(id: Int, title: String, content: String)
  case deletePost(id: Int)
}

extension ExampleAPI: Router {
  public var baseURL: URL {
    return URL(string: "https://example.com/api/v1/")!
  }

  public var path: String {
    switch self {
    case .fetchData:
      return "/posts"
    case .createPost:
      return "/posts"
    case let .updatePost(id, _, _):
      return "/posts/\(id)"
    case let .deletePost(id):
      return "/posts/\(id)"
    }
  }

  public var method: HttpMethod {
    switch self {
    case .fetchData:
      return .get(enableEtag: true, enableDiskCache: true)
    case .createPost:
      return .post
    case .updatePost:
      return .put
    case .deletePost:
      return .delete
    }
  }

  public var task: RouterTask {
    switch self {
    case .fetchData:
      return .requestPlain
    case let .createPost(title, content):
      let parameters = ["title": title, "content": content]
      return .requestParameters(parameters: parameters, type: .body)
    case let .updatePost(_, title, content):
      let parameters = ["title": title, "content": content]
      return .requestParameters(parameters: parameters, type: .body)
    case .deletePost:
      return .requestPlain
    }
  }

  public var headers: [String: String]? {
    return nil
  }
}
```

### Interceptor 구현하기

아래처럼 Interceptor를 구현할 수 있습니다.<br>
`async throws` 타입으로 구현되어, Token 재발급 등의 처리를 할 수 있습니다.

```swift
import FirebaseAuth
import Dessert
import Foundation
import Then

public actor SampleDessertInterceptor: Interceptor {
  private let firebaseAuth: Auth

  init(firebaseAuth: Auth) {
    self.firebaseAuth = firebaseAuth
  }

  public func intercept(_ request: URLRequest) async throws -> URLRequest {
    guard let user = firebaseAuth.currentUser else {
      return request
    }

    let idToken = try await user.getIDToken()

    if request.url?.host?.contains("example.com") == false { return request }

    let newRequest = request.with({
      $0.setValue(idToken, forHTTPHeaderField: "X-USER-ID-TOKEN")
    })

    return newRequest
  }
}
```

### Retrier 구현하기

아래처럼 Retrier 구현할 수 있습니다.<br>
`async`타입으로 구현되어 있습니다.

```swift
import Dessert
import Foundation

public actor SampleDessertRetrier: Retrier {
  public init() {}

  public func retry(router: Router, dueTo error: Error, retryCount: Int) async -> Bool {
    let error = error as NSError

    guard let underlying = error.userInfo[NSUnderlyingErrorKey] as? NSError else {
      return false
    }

    guard
      underlying.domain == NSURLErrorDomain && underlying.code == NSURLErrorNetworkConnectionLost
    else {
      return false
    }

    guard let underlying2 = underlying.userInfo[NSUnderlyingErrorKey] as? NSError else {
      return false
    }

    guard
      let domainKey = underlying2.userInfo["_kCFStreamErrorDomainKey"] as? Int,
      let codeKey = underlying2.userInfo["_kCFStreamErrorCodeKey"] as? Int,
      domainKey == CFStreamErrorDomain.POSIX.rawValue,
      codeKey == ECONNABORTED
    else {
      return false
    }

    return true
  }

}
```

### NetworkMonitor 구현하기

```swift
import Dessert
import Foundation

public actor SampleDessertNetworkEventMonitor: NetworkEventMonitor {
  public init() {}

  public func requestDidStart(_ request: URLRequest) {
    print("""

    ┌─────────────── 🍰 DESSERT Request LOG ───────────────┐
    │ Description: \(request.description)
    │ URL: \(request.url?.absoluteString ?? "")
    │ Method: \(request.httpMethod ?? "")
    │ Headers: \(request.allHTTPHeaderFields ?? [:])
    │ Body: \(request.httpBody?.toPrettyPrintedString ?? "")
    └──────────────────────────────────────────────────────┘

    """)
  }

  public func requestDidFinish(_ request: URLRequest, _ response: URLResponse?, _ data: Data?) {
    guard let response = response as? HTTPURLResponse else { return }

    print("""

    ┌─────────────── 🍰 DESSERT Response LOG ──────────────┐
    │ URL: \(request.url?.absoluteString ?? "")
    │ StatusCode: \(response.statusCode)
    │ Data: \(data?.toPrettyPrintedString ?? "")
    └──────────────────────────────────────────────────────┘

    """)
  }
}

extension Data {
  fileprivate var toPrettyPrintedString: String? {
    guard let object = try? JSONSerialization.jsonObject(with: self, options: []),
          let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
          let prettyPrintedString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else { return nil }
    return prettyPrintedString as String
  }
}

```

### 요청 보내기

#### Common

```swift
import Dessert


public func fetchData() async throws-> ResponseDTO {
  let interceptor = SampleDessertInterceptor(firebaseAuth: .auth())
  let retrier = SampleDessertRetrier()
  let networkEventMonitor = SampleDessertNetworkEventMonitor()

  let routerManager = RouterManager<ExampleAPI>.init(
    interceptor: interceptor,
    retrier: retrier,
    networkEventMonitor: networkEventMonitor,
    diskCacheLoader: .default, // or init
    memoryCacheLoader: .default // or init
  )

  let data = try await routerManager.request(.fetchData, requestType: .remote)

  return try JSONDecoder().decode(ResponseDTO.self, from: data)
}
```

#### Combine

```swift
import CombineDessert

public func fetchData() -> AnyPublisher<ResponseDTO, Error> {
  let interceptor = SampleDessertInterceptor(firebaseAuth: .auth())
  let retrier = SampleDessertRetrier()
  let networkEventMonitor = SampleDessertNetworkEventMonitor()

  let routerManager = RouterManager<ExampleAPI>.init(
    interceptor: interceptor,
    retrier: retrier,
    networkEventMonitor: networkEventMonitor
  )

  return routerManager.request(.fetchData, requestType: .remote)
    .map { try JSONDecoder().decode(ResponseDTO.self, from: $0) }
    .eraseToAnyPublisher()
}
```

#### RxSwift

```swift
import RxDessert

public func fetchData() -> Observable<ResponseDTO> {
  let interceptor = SampleDessertInterceptor(firebaseAuth: .auth())
  let retrier = SampleDessertRetrier()
  let networkEventMonitor = SampleDessertNetworkEventMonitor()

  let routerManager = RouterManager<ExampleAPI>.init(
    interceptor: interceptor,
    retrier: retrier,
    networkEventMonitor: networkEventMonitor
  )

  return routerManager.request(.fetchData, requestType: .remote)
    .map { try JSONDecoder().decode(ResponseDTO.self, from: $0) }
    .asObservable()
}
```

## Swift Package Manager(SPM) 을 통해 사용할 수 있어요

```swift
dependencies: [
  .package(url: "https://github.com/Monsteel/Dessert.git", .upToNextMajor(from: "0.0.1"))
]
```

## 사용하고 있는 곳.

| 회사                                                                                                    | 설명                                                                                                                                                                                                                        |
| ------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| <img src="https://github.com/user-attachments/assets/ddca8614-c940-425c-a0d1-6a0e8f9d2458" height="50"> | SwiftUI와 UIKit을 사용하여 개발된 [정육각 커머스 앱](https://apps.apple.com/kr/app/%EC%A0%95%EC%9C%A1%EA%B0%81-%EC%96%B8%EC%A0%9C%EB%82%98-%EC%B4%88%EC%8B%A0%EC%84%A0/id1490984523)에서 네트워크 통신에 사용하고 있습니다. |

## 함께 만들어 나가요

개선의 여지가 있는 모든 것들에 대해 열려있습니다.<br>
PullRequest를 통해 기여해주세요. 🙏

## License

Dessert 는 MIT 라이선스로 이용할 수 있습니다. 자세한 내용은 [라이선스](https://github.com/Monsteel/Dessert/tree/main/LICENSE) 파일을 참조해 주세요.<br>

## Auther

이영은(Tony) | dev.e0eun@gmail.com

[![Hits](https://hits.seeyoufarm.com/api/count/incr/badge.svg?url=https%3A%2F%2Fgithub.com%2FMonsteel%2FDessert.git&count_bg=%2379C83D&title_bg=%23555555&icon=&icon_color=%23E7E7E7&title=hits&edge_flat=false)](https://hits.seeyoufarm.com)
