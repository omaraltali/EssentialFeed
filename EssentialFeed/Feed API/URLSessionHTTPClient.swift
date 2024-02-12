//
//  URLSessionHTTPClient.swift
//  EssentialFeed
//
//  Created by Omar Alali on 06/02/2023.
//

import Foundation

public final class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
   private struct UnexpectedvaluesRepresentation: Error {}

    private struct URLSessionTaskWrapper: HTTPClientTask {
        
        let wrapped: URLSessionTask

        func cancel() {
            wrapped.cancel()
        }
        
        
    }

    public func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) -> HTTPClientTask {
       let task = session.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
            } else if let data = data, let response = response as? HTTPURLResponse {
                completion(.success((data, response)))
            }
            else {
                completion(.failure(UnexpectedvaluesRepresentation()))
            }
            
        }
        task.resume()
        return URLSessionTaskWrapper(wrapped: task)
    }
}
