//
//  LocalFeedItem.swift
//  EssentialFeed
//
//  Created by Omar Altali on 21/10/2023.
//

import Foundation
// previosly while dealing with tech people we used to call this LocalFeedItem instead of LocalFeedImage
public struct LocalFeedImage: Equatable {
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
