//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Omar Alali on 04/10/2022.
//

import Foundation

public protocol FeedLoader {
    typealias Result = Swift.Result<[FeedImage], Error>

    func load (completion: @escaping (Result) -> Void)
}
 
