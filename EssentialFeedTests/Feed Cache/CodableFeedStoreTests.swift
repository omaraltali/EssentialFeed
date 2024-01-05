//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Omar Altali on 26/12/2023.
//

import XCTest
import EssentialFeed

class CodableFeedStore {

    private struct Cache: Codable {
        let feed: [CodableFeedImage]
        let timestamp: Date

        var localFeed: [LocalFeedImage] {
            return feed.map {$0.local}
        }
    }

    private struct CodableFeedImage: Codable {
        private let id: UUID
        private let description: String?
        private let location: String?
        private let url: URL

        init(_ image: LocalFeedImage) {
            self.id = image.id
            self.description = image.description
            self.location = image.location
            self.url = image.url
        }

        var local: LocalFeedImage {
            return LocalFeedImage(id: id, description: description, location: location, url: url)
        }
    }

    private let storeURL: URL

    init(storeURL: URL) {
        self.storeURL = storeURL
    }

    func retreive(completion: @escaping FeedStore.RetrievalCompletion) {
        guard let  data = try? Data(contentsOf: storeURL) else {
            return completion(.empty)
        }
        do {
            let decoder = JSONDecoder()
            let cache = try decoder.decode(Cache.self, from: data)
            completion(.found(feed: cache.localFeed, timestamp: cache.timestamp))
        } catch {
            completion(.failure(error))
        }

    }
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping FeedStore.InsertionCompletion) {
        let encoder = JSONEncoder()
        let cache = Cache(feed: feed.map(CodableFeedImage.init), timestamp: timestamp)
        let encodedData = try! encoder.encode(cache)
        try! encodedData.write(to: storeURL)
        completion(nil)
    }

}

final class CodableFeedStoreTests: XCTestCase {

    override func setUp() {
        super.setUp()
        setupEmptyStoreState()
    }

    override func tearDown() {
        super.tearDown()
        undoStoreSideEffects()
    }

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

    // - MARK: Helpers

    private func makeSUT(storeURL: URL? = nil, file: StaticString = #file, line: UInt = #line) -> CodableFeedStore {
        let sut = CodableFeedStore(storeURL: storeURL ?? testSepecificStoreURL())
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }

    private func expect(_ sut: CodableFeedStore, toRetriveTwice expectedResult: RetrieveCachedFeedResult, file: StaticString = #file, line: UInt = #line) {
        expect(sut, toRetrive: expectedResult, file: file, line: line)
        expect(sut, toRetrive: expectedResult, file: file, line: line)
    }

    private func expect(_ sut: CodableFeedStore, toRetrive expectedResult: RetrieveCachedFeedResult, file: StaticString = #file, line: UInt = #line) {

        let exp = expectation(description: "wait for cache retrieval")

        sut.retreive { retrievedResult in
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
    private func insert(_ cache: (feed: [LocalFeedImage], timestamp: Date), to sut: CodableFeedStore) -> Error? {
        let exp = expectation(description: "Wait for cache insertion")
        var insertionError: Error?
        sut.insert(cache.feed, timestamp: cache.timestamp) { receivedInsertionError in
            insertionError = receivedInsertionError
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)

        return insertionError
    }

    private func testSepecificStoreURL() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("\(type(of: self)).store")
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
