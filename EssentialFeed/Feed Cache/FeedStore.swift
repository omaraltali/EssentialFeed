//
//  FeedStore.swift
//  EssentialFeed
//
//  Created by Omar Altali on 20/10/2023.
//

import Foundation

public protocol FeedStore {

    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void


    func deleteCachedFeed(completion: @escaping DeletionCompletion)
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion)

}


