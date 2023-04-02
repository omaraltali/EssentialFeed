//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Weird Dev on 4/3/23.
//

import XCTest

class LocalFeedLoader {
    
    init(store: FeedStore) {
        
    }
}
class FeedStore {
    var deleteCachedFeedCallCount = 0
}
class CacheFeedUseCaseTests: XCTestCase {
    
    func test() {
        let store = FeedStore()
        let _ = LocalFeedLoader(store: store)
        XCTAssertEqual(store.deleteCachedFeedCallCount, 0)
    }
}
