//
//  LoadFeedFromCacheUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Omar Altali on 21/10/2023.
//

import XCTest
import EssentialFeed

final class LoadFeedFromCacheUseCaseTests: XCTestCase {

    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()

        XCTAssertEqual(store.receivedMessages, [])
    }

    func test_load_requestCacheRetreival() {
        let (sut, store) = makeSUT()

        sut.load{_ in}
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }

    func test_load_failsOnRetreivalError() {
        let (sut, store) = makeSUT()
        let exp = expectation(description: "Wait for load completion")
        let retrievalError = anyNSError()
        var receivedError: Error?
        sut.load { error in
            receivedError = error
            exp.fulfill()
        }
        store.completeRetrieval(with: retrievalError)

        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(receivedError as NSError?, retrievalError)

    }






    // MARK: - HELPERS

    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line)  -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut,store)
    }


    private func anyNSError() -> NSError {
       return NSError(domain: "any error", code: 0)
    }


}
