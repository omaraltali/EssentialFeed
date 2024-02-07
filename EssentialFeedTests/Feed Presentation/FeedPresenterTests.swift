//
//  FeedPresenterTests.swift
//  EssentialFeedTests
//
//  Created by Omar Altali on 06/02/2024.
//

import XCTest

class FeedPresenter {
    init(view: Any) {

    }
}

final class FeedPresenterTests: XCTestCase {

    func test_init_doesNotSendMessagesToView() {
        let view = ViewSpy()

        _ = FeedPresenter(view: view)

        XCTAssertTrue(view.message.isEmpty, "Expected no view messages")
    }



    // MARK: - Helpers

    private class ViewSpy {
        let message:[Any] = []
    }

}
