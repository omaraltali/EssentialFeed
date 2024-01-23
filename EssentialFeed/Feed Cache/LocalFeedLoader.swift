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

    public typealias SaveResult = Error?

    public func save(_ feed: [FeedImage], completion: @escaping (SaveResult) -> ()) {
        store.deleteCachedFeed { [weak self] error in
            guard let self = self else {return}
            if let cacheDeletionError = error {
                completion(cacheDeletionError)
            } else {
                self.cache(feed, with: completion)
            }
        }
    }

    private func cache(_ feed: [FeedImage],with completion: @escaping (SaveResult) -> Void) {
        store.insert(feed.toLocal(), timestamp: currentDate(), completion: {[weak self] error in
            guard self != nil else {return}
            completion(error)})
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

    public func validateCache() {
        store.retrieve {[weak self] result in
            guard let self else {return}
            switch result {

            case .failure:
                self.store.deleteCachedFeed { _ in }

            case let .success(.found(feed: _,timestamp)) where !FeedCachePolicy.validate(timestamp, against: self.currentDate()):
                self.store.deleteCachedFeed { _ in }

            case .success:
                break
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

