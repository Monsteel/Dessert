
import Foundation

/// 재시도 카운트를 관리합니다.
internal final class RetryContainer<T: Router> {
  /// 재시도 횟수를 저장합니다.
  private var retryCounts: [T: Int] = [:]
  
  /// 재시도 횟수 접근을 동기화하기 위한 락
  private let lock = NSLock()

  /// 최대 재시도 횟수를 저장합니다.
  private var maxRetryCount: Int

  /// RetryContainer 인스턴스를 생성합니다.
  /// - Parameter maxRetryCount: 최대 재시도 횟수
  internal init(maxRetryCount: Int) {
    self.maxRetryCount = maxRetryCount
  }

  /// 재시도 가능한지 확인합니다.
  /// - Parameter router: 라우터
  /// - Returns: 재시도 가능 여부
  internal func isRetryable(router: T) -> Bool {
    lock.lock()
    defer { lock.unlock() }
    return self.getRetryCount(router: router) < self.maxRetryCount
  }

  /// 현재 재시도 횟수를 가져옵니다.
  /// - Parameter router: 라우터
  /// - Returns: 재시도 횟수
  internal func getRetryCount(router: T) -> Int {
    lock.lock()
    defer { lock.unlock() }
    return retryCounts[router] ?? 0
  }

  /// 현재 재시도 횟수를 설정합니다.
  /// - Parameters:
  ///   - router: 라우터
  ///   - count: 재시도 횟수
  internal func setRetryCount(router: T, count: Int) {
    lock.lock()
    defer { lock.unlock() }
    retryCounts[router] = count
  }

  /// 현재 재시도 횟수에 추가합니다.
  /// - Parameters:
  ///   - router: 라우터
  ///   - appendCount: 추가할 재시도 횟수
  internal func appendRetryCount(router: T, appendCount: Int) {
    lock.lock()
    defer { lock.unlock() }
    let currentCount = retryCounts[router] ?? 0
    retryCounts[router] = currentCount + appendCount
  }
}
