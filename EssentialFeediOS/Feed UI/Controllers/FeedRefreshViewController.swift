//
//  FeedRefreshViewController.swift
//  EssentialFeediOS
//
//  Created by Omar Altali on 30/01/2024.
//

import UIKit

protocol FeedRefreshViewControllerDelegate {
    func didRequestFeedRefresh()
}

final class FeedRefreshViewController: NSObject, FeedLoadingView {


    @IBOutlet private var view: UIRefreshControl?

     var delegate: FeedRefreshViewControllerDelegate?


    @IBAction func refresh() {
        delegate?.didRequestFeedRefresh()
    }

    func display(_ viewModel: FeedLoadingViewModel) {
        viewModel.isLoading ? view?.beginRefreshing() : view?.endRefreshing()
    }
}
