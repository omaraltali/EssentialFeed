//
//  FeedErrorViewModel.swift
//  EssentialFeed
//
//  Created by Omar Altali on 08/02/2024.
//

import Foundation

public struct FeedErrorViewModel {
   public let message: String?

    static var noError: FeedErrorViewModel {
        return FeedErrorViewModel(message: nil)
    }

    static func error(message: String) -> FeedErrorViewModel {
        return FeedErrorViewModel(message: message)
    }
}
