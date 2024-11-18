import Foundation
import os

/// 로그와 관련한 함수를 정의합니다.
internal enum Logger {
  /// 로그를 출력합니다.
  /// - Parameters:
  ///   - message: 메시지
  ///   - error: 에러
  static func log(_ message: StaticString, _ error: Error) {
    let nsError = error as NSError
    let userInfo = nsError.userInfo
    os_log(
      .error,
      log: .default,
      "%{public}@\ndomain: %{public}@\ncode: %d\nuserInfo: %{public}@\n",
      "⚠️ [DESSERT] \(message)",
      nsError.domain,
      nsError.code,
      String(describing: userInfo)
    )
  }
}
