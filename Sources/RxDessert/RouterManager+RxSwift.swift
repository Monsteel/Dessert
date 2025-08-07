
import RxSwift
import Dessert
import Foundation

extension RouterManager {
  /// 요청을 보냅니다.
  /// - Parameters:
  ///   - router: ``Router``의 구현체
  ///   - requestType: ``RequestType`` 값, 기본값은 ``RequestType/remote`` 입니다.
  /// - Returns: 요청 결과 데이터
  @available(*, deprecated, message: "이 메서드는 더 이상 사용되지 않습니다. request(_:)를 대체하여 사용하고, requestType은 RouterManager 생성자에서 설정하세요.")
  public func request(_ router: T, requestType: RequestType = .remote) -> Single<Data> {
    return Single.create { observer -> Disposable in
      let task = Task {
        do {
          let data = try await self.request(router, requestType: requestType)
          await MainActor.run {
            observer(.success(data))
          }
        } catch {
          await MainActor.run {
            observer(.failure(error))
          }
        }
      }

      return Disposables.create {
        task.cancel()
      }
    }
  }
  
  /// 요청을 보냅니다.
  /// - Parameters:
  ///   - router: ``Router``의 구현체
  /// - Returns: 요청 결과 데이터
  public func request(_ router: T) -> Single<Data> {
    return Single.create { observer -> Disposable in
      let task = Task {
        do {
          let data = try await self.request(router)
          await MainActor.run {
            observer(.success(data))
          }
        } catch {
          await MainActor.run {
            observer(.failure(error))
          }
        }
      }

      return Disposables.create {
        task.cancel()
      }
    }
  }
}
