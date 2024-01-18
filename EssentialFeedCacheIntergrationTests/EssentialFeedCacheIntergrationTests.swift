//
//  EssentialFeedCacheIntergrationTests.swift
//  EssentialFeedCacheIntergrationTests
//
//  Created by Omar Altali on 16/01/2024.
//

import XCTest
import EssentialFeed

final class EssentialFeedCacheIntergrationTests: XCTestCase {

    override func setUp() {
        super.setUp()
        setupEmptyStoreState()
    }

    override func tearDown() {
        super.tearDown()

        undoStoreSideEffects()
    }

    func test_load_deliversNoItemsOnEmptyCache() {
        let sut = makeSUT()
        expect(sut, toLoad: [])
    }

    func test_load_deliversItemsSavedOnASeparateInstance() {
        let sutToPerformSave = makeSUT()
        let sutToPerformLoad = makeSUT()
        let feed = uniqueImageFeed().models

        expect(sutToPerformSave, toSave: feed)
        expect(sutToPerformLoad, toLoad: feed)
    }

    func test_save_overridesItemSavedOnASeperateInstance() {
        let sutToPerformSave = makeSUT()
        let sutToPerformLastSave = makeSUT()
        let sutToPerformLoad = makeSUT()
        let firstFeed = uniqueImageFeed().models
        let latestFeed = uniqueImageFeed().models

        expect(sutToPerformSave, toSave: firstFeed)
        expect(sutToPerformLastSave, toSave: latestFeed)

        expect(sutToPerformLoad, toLoad: latestFeed)
    }

    // MARK: Helpers

    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> LocalFeedLoader {
        let storeBundle = Bundle(for: CoreDataFeedStore.self)
        let storeURL = testSpecificStoreURL()
        let store = try! CoreDataFeedStore(storeURL: storeURL, bundle: storeBundle)
        let sut = LocalFeedLoader(store: store, currentDate: Date.init)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(store, file: file, line: line)

        return sut
    }

    private func expect(_ sut: LocalFeedLoader, toLoad expectedFeed: [FeedImage], file: StaticString = #file, line: UInt = #line) {

        let exp = expectation(description: "Wait for load completion")
        sut.load { result in
            switch result {
            case .success(let loadedFeed):
                XCTAssertEqual(loadedFeed, expectedFeed, file: file, line: line)
            case .faliure(let error):
                XCTFail("Expected successful feed result, got \(error) instead.", file: file, line: line)
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    private func expect(_ sut: LocalFeedLoader, toSave feed: [FeedImage], file: StaticString = #file, line: UInt = #line) {

        let exp = expectation(description: "Wait for save completion")
        sut.save(feed) { saveError in
            XCTAssertNil(saveError, "Expected to save feed successfully")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    private func setupEmptyStoreState() {
        deleteStoreArtifacts()
    }

    private func undoStoreSideEffects() {
        deleteStoreArtifacts()
    }

    private func deleteStoreArtifacts() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL())
    }


    private func testSpecificStoreURL() -> URL {
        return cachesDirectory().appendingPathComponent("\(type(of: self)).store")
    }

    private func cachesDirectory() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }

}
