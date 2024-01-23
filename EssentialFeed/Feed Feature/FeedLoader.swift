//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Omar Alali on 04/10/2022.
//

import Foundation

public typealias LoadFeedResult = Result<[FeedImage], Error>

public protocol FeedLoader {
    func load (completion: @escaping (LoadFeedResult) -> Void)
}
 
