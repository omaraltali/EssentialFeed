//
//  RemoteFeedImageDataLoader.swift
//  EssentialFeed
//
//  Created by Omar Altali on 17/02/2024.
//

import Foundation


public final class RemoteFeedImageDataLoader: FeedImageDataLoader {
    private let client: HTTPClient

   public init(client: HTTPClient) {
        self.client = client
    }

    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }

    private final class HTTPClientTaskWrapper: FeedImageDataLoaderTask {
        private var completion: ((FeedImageDataLoader.Result) -> Void)?

        var wrapped: HTTPClientTask?

        init(_ completion: @escaping (FeedImageDataLoader.Result) -> Void) {
            self.completion = completion
        }

        func complete(with result: FeedImageDataLoader.Result) {
            completion?(result)
        }

        func cancel() {
            preventFurtherCompletions()
            wrapped?.cancel()
        }

        private func preventFurtherCompletions() {
            completion = nil
        }
    }

    @discardableResult
    public func loadImageData(from url: URL, completion: @escaping (FeedImageDataLoader.Result) -> Void) -> FeedImageDataLoaderTask {
        let task = HTTPClientTaskWrapper(completion)
        task.wrapped = client.get(from: url) { [weak self] result in
            guard  self != nil else { return }

//            switch result {
//            case let .success((data, response)):
//                if response.statusCode == 200, !data.isEmpty {
//                    task.complete(with: .success(data))
//                } else {
//                    task.complete(with: .failure(Error.invalidData))
//                }
//            case .failure:
//                task.complete(with: .failure(Error.connectivity))
//            }

            task.complete(with: result
                .mapError{_ in Error.connectivity}
                .flatMap({ data, response in
                    let isValidResponse = response.isOK && !data.isEmpty
                    return isValidResponse ? .success(data) : .failure(Error.invalidData)
                })
            )
        }
        return task
    }

}
