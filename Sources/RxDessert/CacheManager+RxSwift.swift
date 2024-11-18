
import RxSwift
import Dessert
import Foundation

extension CacheManager {

  /// 메모리 캐시와 디스크 캐시를 초기화합니다.
  ///
  /// 초기화 외 다른 접근은 불가능합니다.
  public func clear() -> Single<Void> {
    return Single.create { observer -> Disposable in
      let task = Task {
        do {
          try await self.clear()
          await MainActor.run {
            observer(.success(()))
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
