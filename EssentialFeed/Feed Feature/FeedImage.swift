//
//  FeedItem.swift
//  EssentialFeed
//
//  Created by Omar Alali on 04/10/2022.
//

import Foundation
// used to be called FeedItem
public struct FeedImage: Equatable {
    public let id: UUID
    public let description: String?
    public let location: String?
    public let url: URL
    
    public init (id: UUID,description: String?, location: String? ,url: URL  ) {
        
        self.id = id
        self.description = description
        self.location = location
        self.url = url
    }
}
