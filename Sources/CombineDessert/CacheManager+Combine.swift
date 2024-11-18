
import Combine
import Dessert
import Foundation

extension CacheManager {

  /// 메모리 캐시와 디스크 캐시를 초기화합니다.
  ///
  /// 초기화 외 다른 접근은 불가능합니다.
  public func clear() -> AnyPublisher<Void, Error> {
    let subject = PassthroughSubject<Void, Error>()

    let task = Task {
      do {
        try await self.clear()
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
