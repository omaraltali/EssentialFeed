//
//  FeedPresenter.swift
//  EssentialFeediOS
//
//  Created by Omar Altali on 01/02/2024.
//

import UIKit
import EssentialFeed

struct FeedLoadingViewModel {
    let isLoading: Bool
}
struct FeedViewModel {
    let feed: [FeedImage]
}

struct FeedErrorViewModel { // Added
    let message: String
}

protocol FeedErrorView { // Added
    func display(_ viewModel: FeedErrorViewModel)
}


protocol FeedLoadingView {
    func display(_ viewModel: FeedLoadingViewModel)
}

protocol FeedView {
    func display(_ viewModel: FeedViewModel)
}
final class FeedPresenter {
    private let feedView: FeedView
    private let loadingView: FeedLoadingView
    private let errorView: FeedErrorView // Added

    init(feedView: FeedView, loadingView: FeedLoadingView, errorView: FeedErrorView) { // Added
        self.feedView = feedView
        self.loadingView = loadingView
        self.errorView = errorView // Added
    }

    static var title: String {
        return NSLocalizedString("FEED_VIEW_TITLE",
            tableName: "Feed",
            bundle: Bundle(for: FeedPresenter.self),
            comment: "Title for the feed view")
    }

    private var feedLoadError: String { // Added
        return NSLocalizedString("FEED_VIEW_CONNECTION_ERROR",
             tableName: "Feed",
             bundle: Bundle(for: FeedPresenter.self),
             comment: "Error message displayed when we can't load the image feed from the server")
    }

    func didStartLoadingFeed() {
        loadingView.display(FeedLoadingViewModel(isLoading: true))
    }

    func didFinishLoadingFeed(with feed: [FeedImage]) {
        feedView.display(FeedViewModel(feed: feed))
        loadingView.display(FeedLoadingViewModel(isLoading: false))
    }

    func didFinishLoadingFeed(with error: Error) {
        errorView.display(FeedErrorViewModel(message: feedLoadError)) // Added
        loadingView.display(FeedLoadingViewModel(isLoading: false))
    }
}
