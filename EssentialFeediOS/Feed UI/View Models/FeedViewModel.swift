//
//  FeedViewModel.swift
//  EssentialFeediOS
//
//  Created by Omar Altali on 31/01/2024.
//

import Foundation
import EssentialFeed

final class FeedViewModel {

    typealias Observer<T> = (T) -> Void
    private let feedLoader: FeedLoader

    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }

    // COMBINE || RXSwift || Closuers
    var onLoadingStateChange: Observer<Bool>?
    var onFeedLoad: Observer<[FeedImage]>?

    func loadFeed() {
        onLoadingStateChange?(true)
        feedLoader.load { [weak self] result in
            if let feed = try? result.get() {
                self?.onFeedLoad?(feed)
            }
            self?.onLoadingStateChange?(false)
        }
    }
}
