//
//  File.swift
//  NetworkKit
//
//  Created by Tony on 11/15/24.
//

import Combine
import NetworkKit
import Foundation

extension RouterManager {
  public func request() -> AnyPublisher<Data, Error> {
    let subject = PassthroughSubject<Data, Error>()

    let task = Task {
      do {
        let data = try await self.request()
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
