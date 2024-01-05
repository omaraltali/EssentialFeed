//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Omar Altali on 26/12/2023.
//

import XCTest
import EssentialFeed


final class CodableFeedStoreTests: XCTestCase {

    override func setUp() {
        super.setUp()
        setupEmptyStoreState()
    }

    override func tearDown() {
        super.tearDown()
        undoStoreSideEffects()
    }

    // - MARK: Retreive Tests

    func test_retreieve_deliversEmptyOnEmptyCache() {
        let sut = makeSUT()

        expect(sut, toRetrive: .empty)
    }

    func test_retreieve_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()

        expect(sut, toRetriveTwice: .empty)
    }

    func test_retrive_deliversFiundValuesOnNonEmptyCache() {
        let sut = makeSUT()
        let feed = uniqueImageFeed().local
        let timestamp = Date()

        insert((feed,timestamp), to: sut)
        expect(sut, toRetrive: .found(feed: feed, timestamp: timestamp))
    }

    func test_retreieve_hasNoSideEffectOnNonEmptyCache() {
        let sut = makeSUT()
        let feed = uniqueImageFeed().local
        let timestamp = Date()

        insert((feed,timestamp), to: sut)
        expect(sut, toRetriveTwice: .found(feed: feed, timestamp: timestamp))

    }

    func test_retrieve_deliversFailureOnTerivalError() {
        let storeURL = testSepecificStoreURL()
        let sut = makeSUT(storeURL: storeURL)

        try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
        expect(sut, toRetrive: .failure(anyNSError()))
    }

    func test_retrieve_hasNoSideEffectsOnFailure() {
        let storeURL = testSepecificStoreURL()
        let sut = makeSUT(storeURL: storeURL)

        try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
        
        expect(sut, toRetriveTwice: .failure(anyNSError()))
    }

    // - MARK: Insertion Tests

    func test_insert_overridesPreviouslyInsertedCacheValues() {
        let sut = makeSUT()

        let firstInsertionError = insert((uniqueImageFeed().local, Date()), to: sut)
        XCTAssertNil(firstInsertionError, "Expected to insert cache successfully")

        let latestFeed = uniqueImageFeed().local
        let latestTimestamp = Date()
        let latestInsertionError = insert((latestFeed, latestTimestamp), to: sut)

        XCTAssertNil(latestInsertionError, "Expected to override cache successfully")
        expect(sut, toRetrive: .found(feed: latestFeed, timestamp: latestTimestamp))
    }

    func test_insert_deliversErrorOnInsertionError() {
        let invalidStoreURL = URL(string: "invalid://store-url")
        let sut = makeSUT(storeURL: invalidStoreURL)
        let feed = uniqueImageFeed().local
        let timestamp = Date()

        let insertionError = insert((feed,timestamp), to: sut)

        XCTAssertNotNil(insertionError)
    }

    // - MARK: Deletion Tests

    func test_delete_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()
        let deletionError = deleteCache(from: sut)

        XCTAssertNil(deletionError, "Expected empty cache deletion to succceed")
        expect(sut, toRetrive: .empty)
    }

    func test_delete_emptiesPreviouslyInsertedCache() {
        let sut = makeSUT()
        insert((uniqueImageFeed().local, Date()), to: sut)
        let deletionError = deleteCache(from: sut)

        XCTAssertNil(deletionError,"Expected empty cache deletion to succceed")
        expect(sut, toRetrive: .empty)
    }

    func test_delete_deliversErrorOnDeletionError() {
        let noDeletePermissionURL = cachesDirectory()
        let sut = makeSUT(storeURL: noDeletePermissionURL)
        let deletionError = deleteCache(from: sut)

        XCTAssertNotNil(deletionError, "Expected cache deletion to fail")
        expect(sut, toRetrive: .empty)
    }

    // - MARK: Helpers

    private func makeSUT(storeURL: URL? = nil, file: StaticString = #file, line: UInt = #line) -> FeedStore {
        let sut = CodableFeedStore(storeURL: storeURL ?? testSepecificStoreURL())
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }

    private func expect(_ sut: FeedStore, toRetriveTwice expectedResult: RetrieveCachedFeedResult, file: StaticString = #file, line: UInt = #line) {
        expect(sut, toRetrive: expectedResult, file: file, line: line)
        expect(sut, toRetrive: expectedResult, file: file, line: line)
    }

    private func expect(_ sut: FeedStore, toRetrive expectedResult: RetrieveCachedFeedResult, file: StaticString = #file, line: UInt = #line) {

        let exp = expectation(description: "wait for cache retrieval")

        sut.retrieve { retrievedResult in
            switch (expectedResult, retrievedResult) {
            case (.empty, .empty), (.failure, .failure):
                break

            case let (.found(expected),.found(retrived)):
                XCTAssertEqual(retrived.feed, expected.feed, file: file, line: line)
                XCTAssertEqual(retrived.timestamp, expected.timestamp, file: file, line: line)

            default:
                XCTFail("Expected to retrive \(expectedResult), got \(retrievedResult) instead.", file: file, line: line)
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    @discardableResult
    private func insert(_ cache: (feed: [LocalFeedImage], timestamp: Date), to sut: FeedStore) -> Error? {
        let exp = expectation(description: "Wait for cache insertion")
        var insertionError: Error?
        sut.insert(cache.feed, timestamp: cache.timestamp) { receivedInsertionError in
            insertionError = receivedInsertionError
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)

        return insertionError
    }

    private func deleteCache(from sut: FeedStore) -> Error? {
        let exp = expectation(description: "Wait for cache deletion")
        var deletionError: Error?
        sut.deleteCachedFeed { receivedDeletionError in
            deletionError = receivedDeletionError
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return deletionError
    }

    private func testSepecificStoreURL() -> URL {
        return cachesDirectory().appendingPathComponent("\(type(of: self)).store")
    }

    private func cachesDirectory() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }

    private func undoStoreSideEffects() {
        deleteStoreArtifacts()
    }

    private func setupEmptyStoreState() {
        deleteStoreArtifacts()
    }

    private func deleteStoreArtifacts() {
        try? FileManager.default.removeItem(at: testSepecificStoreURL())
    }

}
