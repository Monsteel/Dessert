//
//  File.swift
//  NetworkKit
//
//  Created by Tony on 11/15/24.
//

import RxSwift
import NetworkKit
import Foundation

extension RouterManager {
  public func request() -> Single<Data> {
    return Single.create { observer -> Disposable in
      let task = Task {
        do {
          let data = try await self.request()
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
