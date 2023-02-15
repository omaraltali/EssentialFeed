//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Omar Alali on 04/10/2022.
//

import Foundation

public enum LoadFeedResult {
    case success([FeedItem])
    case faliure(Error)
}

public protocol FeedLoader {
    func load (completion: @escaping (LoadFeedResult) -> Void)
}
 
