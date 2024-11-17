
import Foundation
import os

internal enum Logger {
  static func log(_ message: StaticString, _ error: Error) {
    os_log(.error, log: .default, message, error.localizedDescription)
  }
}
