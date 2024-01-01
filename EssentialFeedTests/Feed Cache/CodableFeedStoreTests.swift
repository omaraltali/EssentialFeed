//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Omar Altali on 26/12/2023.
//

import XCTest
import EssentialFeed

class CodableFeedStore {

    func retreive(completion: @escaping FeedStore.RetrievalCompletion) {
        completion(.empty)
    }
}

final class CodableFeedStoreTests: XCTestCase {


    func test_retreieve_deliversEmptyOnEmptyCache() {

        let sut = CodableFeedStore()
        let exp = expectation(description: "Wait for cache retrieval")
        sut.retreive { result in
            switch result {
            case .empty:
                break
            default:
                XCTFail("Expected empty result, got \(result) instead")
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }

    func test_retreieve_hasNoSideEffectsOnEmptyCache() {

        let sut = CodableFeedStore()
        let exp = expectation(description: "Wait for cache retrieval")
        sut.retreive { firstResult in
            sut.retreive { secondResult in
                switch (firstResult, secondResult) {
                case (.empty, .empty):
                    break
                default:
                    XCTFail("Expected empty result, got \(firstResult) and \(secondResult) instead")
                }
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }

}
