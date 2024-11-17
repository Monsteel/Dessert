
import Foundation

internal enum RouterManagerErrorFactory {
  private enum Code: Int {
    case requestTypeError = 0
    case failedCreateURLRequest = 1
    case responseDataIsNil = 2
    case urlResponseIsNil = 3
    case badResponse = 4
    case urlIsNil = 5
  }

  internal static func requestTypeError() -> NSError {
    NSError(
      domain: "\(Self.self)",
      code: Code.requestTypeError.rawValue,
      userInfo: nil
    )
  }

  internal static func failedCreateURLRequest(_ underlying: Error) -> NSError {
    NSError(
      domain: "\(Self.self)",
      code: Code.failedCreateURLRequest.rawValue,
      userInfo: [
        NSUnderlyingErrorKey: underlying
      ]
    )
  }

  internal static func responseDataIsNil() -> NSError {
    NSError(
      domain: "\(Self.self)",
      code: Code.responseDataIsNil.rawValue,
      userInfo: nil
    )
  }

  internal static func urlResponseIsNil() -> NSError {
    NSError(
      domain: "\(Self.self)",
      code: Code.urlResponseIsNil.rawValue,
      userInfo: nil
    )
  }

  internal static func badResponse(_ response: HTTPURLResponse) -> NSError {
    NSError(
      domain: "\(Self.self)",
      code: Code.badResponse.rawValue,
      userInfo: nil
    )
  }

  internal static func urlIsNil() -> NSError {
    NSError(
      domain: "\(Self.self)",
      code: Code.urlIsNil.rawValue,
      userInfo: nil
    )
  }
}
