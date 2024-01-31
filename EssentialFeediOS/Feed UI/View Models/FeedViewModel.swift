//
//  FeedViewModel.swift
//  EssentialFeediOS
//
//  Created by Omar Altali on 31/01/2024.
//

import Foundation
import EssentialFeed

final class FeedViewModel {

    private let feedLoader: FeedLoader

    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }

   private (set) var isLoading: Bool = false {
       didSet {onChange?(self)}
    }

    // COMBINE || RXSwift || Closuers
    var onChange: ((FeedViewModel) -> Void)?
    var onFeedLoad: (([FeedImage]) -> Void)?

    func loadFeed() {
        isLoading = true
        feedLoader.load { [weak self] result in
            if let feed = try? result.get() {
                self?.onFeedLoad?(feed)
            }
            self?.isLoading = false
        }
    }
}
