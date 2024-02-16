//
//  HTTPURLResponse+StatusCode.swift
//  EssentialFeed
//
//  Created by Omar Altali on 17/02/2024.
//

import Foundation

extension HTTPURLResponse {
    private static var OK_200: Int { return 200 }

    var isOK: Bool {
        return statusCode == HTTPURLResponse.OK_200
    }
}
