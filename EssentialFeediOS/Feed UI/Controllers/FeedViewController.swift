//
//  FeedViewController.swift
//  EssentialFeediOS
//
//  Created by Omar Altali on 27/01/2024.
//

import UIKit

protocol FeedViewControllerDelegate {
    func didRequestFeedRefresh()
}

public final class ErrorView: UIView {
    public var message: String?
}

public final class FeedViewController: UITableViewController, UITableViewDataSourcePrefetching, FeedLoadingView, FeedErrorView { // Added implement FeedErrorView

    public let errorView = ErrorView() // Added

    var delegate: FeedViewControllerDelegate?

    var tableModel = [FeedImageCellController]() {
        didSet { tableView.reloadData() }
    }


    public override func viewDidLoad() {
        super.viewDidLoad()

        refresh()
    }

    public override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        refresh()
    }

     @IBAction private func refresh() {
        delegate?.didRequestFeedRefresh()
    }

    func display(_ viewModel: FeedLoadingViewModel) {
        viewModel.isLoading ? refreshControl?.beginRefreshing() : refreshControl?.endRefreshing()
    }

    func display(_ viewModel: FeedErrorViewModel) {
        errorView.message = viewModel.message // Added
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableModel.count
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return cellController(forRowAt: indexPath).view(in: tableView)
    }

    public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { indexPath in
            cellController(forRowAt: indexPath).preload()
        }
    }


    public override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cancelCellControllerLoad(forRowAt: indexPath)
    }

    public func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach(cancelCellControllerLoad)

//        for indexPath in indexPaths {
//            cancelCellControllerLoad(forRowAt: indexPath)
//        }
    }

    private func cellController(forRowAt indexPath: IndexPath) -> FeedImageCellController {
        return tableModel[indexPath.row]
    }

    private func cancelCellControllerLoad(forRowAt indexPath: IndexPath) {
        cellController(forRowAt: indexPath).cancelLoad()
    }
}
