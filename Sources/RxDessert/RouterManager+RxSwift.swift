
import RxSwift
import Dessert
import Foundation

extension RouterManager {
  /// 요청을 보냅니다.
  /// - Parameters:
  ///   - router: ``Router``의 구현체
  /// - Returns: 요청 결과 데이터
  public func request(_ router: T) -> Single<Data> {
    return Single.create { observer -> Disposable in
      let task = Task {
        do {
          let data = try await self.request(router)
          observer(.success(data))
        } catch {
          observer(.failure(error))
        }
      }

      return Disposables.create {
        task.cancel()
      }
    }
  }
}
