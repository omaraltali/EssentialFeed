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

    private let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("image-feed.store")

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

    override class func setUp() {
        super.setUp()

        let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("image-feed.store")
        try? FileManager.default.removeItem(at: storeURL)
    }

    override class func tearDown() {
        super.tearDown()

        let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("image-feed.store")
        try? FileManager.default.removeItem(at: storeURL)
    }

    func test_retreieve_deliversEmptyOnEmptyCache() {
        let sut = makeSUT()
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

        let sut = makeSUT()
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

    func test_retreieveAfterInsertingToEmptyCache_deliversInsertedValues() {

        let sut = makeSUT()
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        let exp = expectation(description: "Wait for cache retrieval")

        sut.insert(feed, timestamp: timestamp) { insertionError in

            XCTAssertNil(insertionError, "Expected feed to be inserted successfully")

            sut.retreive { retriveResult in
                switch retriveResult {
                case let .found(retrivedFeed, retrivedTimestamp):
                    XCTAssertEqual(retrivedFeed, feed)
                    XCTAssertEqual(retrivedTimestamp, timestamp)
                default:
                    XCTFail("Expected found result with feed \(feed) and timestamp \(timestamp), got \(retriveResult) instead")
                }

                exp.fulfill()
            }
        }

        wait(for: [exp], timeout: 1.0)
    }

    // - MARK: Helpers

    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> CodableFeedStore {
        let sut = CodableFeedStore()
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }

}
