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
        let decoder = JSONDecoder()
        let cache = try! decoder.decode(Cache.self, from: data)
        completion(.found(feed: cache.localFeed, timestamp: cache.timestamp))

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

    func test_retreieveAfterInsertingToEmptyCache_deliversInsertedValues() {

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


    // - MARK: Helpers

    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> CodableFeedStore {
        let sut = CodableFeedStore(storeURL: testSepecificStoreURL())
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
            case (.empty, .empty):
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

    private func insert(_ cache: (feed: [LocalFeedImage], timestamp: Date), to sut: CodableFeedStore) {
        let exp = expectation(description: "Wait for cache insertion")
        sut.insert(cache.feed, timestamp: cache.timestamp) { insertionError in
            XCTAssertNil(insertionError, "Expected feed to be inserted successfully")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
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
