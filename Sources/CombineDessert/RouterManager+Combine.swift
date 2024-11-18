
import Combine
import Dessert
import Foundation

extension RouterManager {
  /// 요청을 보냅니다.
  /// - Parameters:
  ///   - router: ``Router``의 구현체
  ///   - requestType: ``RequestType`` 값, 기본값은 ``RequestType/remote`` 입니다.
  /// - Returns: 요청 결과 데이터
  public func request(_ router: T, requestType: RequestType = .remote) -> AnyPublisher<Data, Error> {
    let subject = PassthroughSubject<Data, Error>()

    let task = Task {
      do {
        let data = try await self.request(router, requestType: requestType)
        subject.send(data)
        subject.send(completion: .finished)
      } catch {
        subject.send(completion: .failure(error))
      }
    }

    return subject
      .handleEvents(receiveCancel: task.cancel)
      .eraseToAnyPublisher()
  }
}
