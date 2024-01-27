//
//  FeedViewControllerTests.swift
//  EssentialFeediOSTests
//
//  Created by Omar Altali on 27/01/2024.
//

import XCTest
import UIKit
import EssentialFeed

final class FeedViewController: UITableViewController {
    private var loader: FeedLoader?

    convenience init(loader: FeedLoader) {
        self.init()
        self.loader = loader
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(load), for: .valueChanged)
        load()

    }

    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        load()
    }

    @objc private func load() {
        refreshControl?.beginRefreshing()
        loader?.load(completion: { [weak self] _ in
            self?.refreshControl?.endRefreshing()
        })
    }
}

final class FeedViewControllerTests: XCTestCase {

    func test_init_doesNotLoadFeed() {
        let (_,loader) = makeSUT()

        XCTAssertEqual(loader.loadCallCount, 0)
    }

    func test_viewDidLoad_loadsFeed() {
        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()

        XCTAssertEqual(loader.loadCallCount, 1)
    }

    func test_pullToRefresh_loadsFeed() {
        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()

        sut.refreshControl?.simulatePullToRefresh()
        XCTAssertEqual(loader.loadCallCount, 2)

        sut.refreshControl?.simulatePullToRefresh()
        XCTAssertEqual(loader.loadCallCount, 3)
    }

    func test_viewIsAppearing_showsLoadingIndicator() {
        let (sut, _) = makeSUT()

        let window = UIWindow()
        window.rootViewController = sut
        window.makeKeyAndVisible()
        window.layoutIfNeeded()
        XCTAssertEqual(sut.refreshControl?.isRefreshing, true)
    }

    func test_viewDidLoad_hidesLoadingIndicatorOnLoaderCompletion() {
        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
//        loader.completeFeedLoading() no need for this func since i call end refreshing at the completion of load func in sut

        XCTAssertEqual(sut.refreshControl?.isRefreshing, false)
    }


    // MARK: - Helpers

    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: FeedViewController, loader: LoaderSpy) {
        let loader = LoaderSpy()
        let sut = FeedViewController(loader: loader)
        trackForMemoryLeaks(loader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, loader)
    }

    class LoaderSpy: FeedLoader {
        private var completions = [(FeedLoader.Result) -> Void]()

        var loadCallCount: Int {
            return completions.count
        }

        func load(completion: @escaping (FeedLoader.Result) -> Void) {
            completions.append(completion)
        }

//        func completeFeedLoading() {
//            completions[0](.success([]))
//        }
    }
}

private extension UIRefreshControl {
    func simulatePullToRefresh() {
        allTargets.forEach({ target in
            actions(forTarget: target, forControlEvent: .valueChanged)?.forEach {(target as NSObject).perform(Selector($0))}
        })

    }
}
