//
//  HTTPClient.swift
//  EssentialFeed
//
//  Created by Omar Alali on 20/12/2022.
//

import Foundation

public enum HTTPClientResult {
    case success(Data, HTTPURLResponse)
    case failure(Error)
}


public protocol HTTPClient {
    func get (from url: URL, completion: @escaping (HTTPClientResult) -> Void)
}


