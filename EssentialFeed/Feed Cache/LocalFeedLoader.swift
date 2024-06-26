//
//  LocalFeedLoader.swift
//  EssentialFeed
//
//  Created by Omar Altali on 20/10/2023.
//

import Foundation

public final class LocalFeedLoader {

    private let currentDate: () -> Date
    private let store: FeedStore

    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }

}

// MARK: Save & Cache
extension LocalFeedLoader {

    public typealias SaveResult = Result<Void,Error>

    public func save(_ feed: [FeedImage], completion: @escaping (SaveResult) -> Void) {
        store.deleteCachedFeed { [weak self] deletionResult in
            guard let self = self else {return}

            switch deletionResult {
            case .success:
                self.cache(feed, with: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func cache(_ feed: [FeedImage],with completion: @escaping (SaveResult) -> Void) {
        store.insert(feed.toLocal(), timestamp: currentDate()) {[weak self] insertionResult in
            guard self != nil else {return}
            completion(insertionResult)
        }
    }

}

// MARK: Load
extension LocalFeedLoader: FeedLoader {

    public typealias LoadResult = FeedLoader.Result

    public func load (completion: @escaping (LoadResult) -> Void) {
        //store.retrieve{error in completion(error)}
        store.retrieve { [weak self] result in
            guard let self = self else {return}
            switch result {
            case let .failure(error):
                completion(.failure(error))
            case let .success(.found(feed,timestamp)) where FeedCachePolicy.validate(timestamp, against: self.currentDate()):
                completion(.success(feed.toModels()))
            case .success:
                completion(.success([]))
            }
        }
    }
}


// MARK: Validate Cache
extension LocalFeedLoader {

    public typealias ValidationResult = Result<Void, Error>

    public func validateCache(completion: @escaping (ValidationResult) -> Void = { _ in }) {
        store.retrieve {[weak self] result in
            guard let self else {return}
            switch result {

            case .failure:
                self.store.deleteCachedFeed(completion: completion)

            case let .success(.found(feed: _,timestamp)) where !FeedCachePolicy.validate(timestamp, against: self.currentDate()):
                self.store.deleteCachedFeed(completion: completion)

            case .success:
                completion(.success(()))
            }
        }
    }
}


private extension Array where Element == FeedImage {
    func toLocal() -> [LocalFeedImage] {
        return map {LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)}
    }
}
private extension Array where Element == LocalFeedImage {

    func toModels() -> [FeedImage] {
        return map{FeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)}
    }
}

