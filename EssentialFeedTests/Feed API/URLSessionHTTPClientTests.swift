//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Omar Alali on 23/01/2023.
//

import XCTest
import EssentialFeed

final class URLSessionHTTPClientTests: XCTestCase {

    
    override func tearDown() {
        super.tearDown()
        URLProtocolStub.removeStub()
    }
    
    func test_getFromURL_performsGETRequestWithURL() {
        
        let url = anyURL()
        let exp = expectation(description: "Wait for request")
        URLProtocolStub.observeRequests { request in
            
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        }
        
        makeSUT().get(from: url) { _ in}
        
        wait(for: [exp], timeout: 1.0)
        
    }

    func test_cancelGetFromURLTask_cancelsURLRequest() {
        let exp = expectation(description: "Wait for request")
        URLProtocolStub.observeRequests { _ in exp.fulfill() }

        let receivedError = resultErrorFor(taskHandler: { $0.cancel() }) as NSError?
        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(receivedError?.code, URLError.cancelled.rawValue)
    }

    func test_getFromURL_failsOnRequestError() {
        let requestError = anyNSError()
        let receivedError = resultErrorFor((data: nil, response: nil, error: requestError))

        XCTAssertEqual(receivedError?.localizedDescription, requestError.localizedDescription)
    }
    
    func test_getFromURL_failsOnAllInvalidRepresentationCases() {
        
        XCTAssertNotNil(resultErrorFor((data: nil, response: nil, error: nil)))
        XCTAssertNotNil(resultErrorFor((data: nil, response: nonHTTPURLResponse(), error: nil)))
        XCTAssertNotNil(resultErrorFor((data: anyData(), response: nil, error: nil)))
        XCTAssertNotNil(resultErrorFor((data: anyData(), response: nil, error: anyNSError())))
        XCTAssertNotNil(resultErrorFor((data: nil, response: nonHTTPURLResponse(), error: anyNSError())))
        XCTAssertNotNil(resultErrorFor((data: nil, response: anyHTTPURLResponse(), error: anyNSError())))
        XCTAssertNotNil(resultErrorFor((data: anyData(), response: nonHTTPURLResponse(), error: anyNSError())))
        XCTAssertNotNil(resultErrorFor((data: anyData(), response: anyHTTPURLResponse(), error: anyNSError())))
        XCTAssertNotNil(resultErrorFor((data: anyData(), response: nonHTTPURLResponse(), error: nil)))    }

    func test_getFromURL_succeedsOnHTTPURLResponseWithData() {
        let data = anyData()
        let response = anyHTTPURLResponse()
        let receivedValues = resultValuesFor((data: data, response: response, error: nil))

        XCTAssertEqual(receivedValues?.data, data)
        XCTAssertEqual(receivedValues?.response.url, response.url)
        XCTAssertEqual(receivedValues?.response.statusCode, response.statusCode)
        
    }
    
    func test_getFromURL_succeedsWithEmptyDataOnHTTPURLResponseWithNilData() {
        let response = anyHTTPURLResponse()
        let receivedValues = resultValuesFor((data: nil, response: response, error: nil))

        let emptyData = Data()
        XCTAssertEqual(receivedValues?.data, emptyData)
        XCTAssertEqual(receivedValues?.response.url, response.url)
        XCTAssertEqual(receivedValues?.response.statusCode, response.statusCode)
    }
    
    
    
    
    
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> HTTPClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: configuration)
        let sut = URLSessionHTTPClient(session: session)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return sut
    }
    

    private func anyNSError() -> NSError {
       return NSError(domain: "any error", code: 0)
    }
    private func anyHTTPURLResponse() -> HTTPURLResponse {
        return HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
    }
    
    private func nonHTTPURLResponse() -> URLResponse {
        return URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
    }
    
    private func resultValuesFor(_ values: (data: Data?, response: URLResponse?, error: Error?), file: StaticString = #file, line: UInt = #line) -> (data: Data, response: HTTPURLResponse)? {
        let result = resultFor(values, file: file, line: line)

        switch result {
        case let .success(data, response):
            return (data,response)
            
        default:
            XCTFail("Expected Success, got \(result) instead.",file: file, line: line)
            return nil
        }
    }
    
    private func resultErrorFor(_ values: (data: Data?, response: URLResponse?, error: Error?)? = nil, taskHandler: (HTTPClientTask) -> Void = { _ in }, file: StaticString = #file, line: UInt = #line) -> Error? {

        let result = resultFor(values, taskHandler: taskHandler, file: file, line: line)
        switch result {
        case let .failure(error):
            return error
            
        default:
            XCTFail("Expected to fail, got \(result)instead", file: file, line: line)
            return nil
        }
    }
    
    private func resultFor(_ values: (data: Data?, response: URLResponse?, error: Error?)?, taskHandler: (HTTPClientTask) -> Void = { _ in },  file: StaticString = #file, line: UInt = #line) -> HTTPClient.Result {
        values.map { URLProtocolStub.stub(data: $0, response: $1, error: $2) }


        let exp = expectation(description: "Wait for completion")
        let sut = makeSUT(file: file, line: line)

        var receivedResult: HTTPClient.Result!
        taskHandler(sut.get(from: anyURL(), completion: { result in
            receivedResult = result
            exp.fulfill()
        }))

        wait(for: [exp], timeout: 1.0)
        return receivedResult
        
    }

    // MARK: - URLProtocolStub

    private class URLProtocolStub: URLProtocol {
        private struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
            let requestObserver: ((URLRequest) -> Void)?
        }

        private static var _stub: Stub?
        private static var stub: Stub? {
            get { return queue.sync { _stub } }
            set { queue.sync { _stub = newValue } }
        }

        private static let queue = DispatchQueue(label: "URLProtocolStub.queue")

        static func stub(data: Data?, response: URLResponse?, error: Error?) {
            stub = Stub(data: data, response: response, error: error, requestObserver: nil)
        }

        static func observeRequests(observer: @escaping (URLRequest)->()){
            stub = Stub(data: nil, response: nil, error: nil, requestObserver: observer)
        }


        static func removeStub() {
            stub = nil
        }

        class override func canInit(with request: URLRequest) -> Bool {
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {

            guard let stub = URLProtocolStub.stub else { return }

            if let data = stub.data {
                client?.urlProtocol(self, didLoad: data)
            }

            if let response = stub.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }

            if let error = stub.error {
                client?.urlProtocol(self, didFailWithError: error)
            } else {
                client?.urlProtocolDidFinishLoading(self)
            }

            stub.requestObserver?(request)

        }
        
        override func stopLoading() {}
        
    }
    
}
