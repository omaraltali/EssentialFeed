//
//  URLSessionHTTPClient.swift
//  EssentialFeed
//
//  Created by Omar Alali on 06/02/2023.
//

import Foundation

public class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
   private struct UnexpectedvaluesRepresentation: Error {}
    
    public func get(from url: URL, completion: @escaping (HTTPClientResult) -> ()){
        session.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
            } else if let data = data, let response = response as? HTTPURLResponse {
                completion(.success(data, response))
            }
            else {
                completion(.failure(UnexpectedvaluesRepresentation()))
            }
            
        }
        .resume()
    }
}
