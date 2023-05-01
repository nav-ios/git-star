//
//  GitStarTests.swift
//  GitStarTests
//
//  Created by Nav on 01/05/23.
//

import XCTest
@testable import GitLoader

class RemoteGitLoader{
    private let client: HTTPClient
    
    public enum Error: Swift.Error{
        case noConnectivity
        case invalidData
    }
    
    init(client: HTTPClient) {
        self.client = client
    }
    
    func load(completion: @escaping (Error) -> Void){
        client.getRepos(){ data, error in
            if let error{
                completion(.noConnectivity)
            }else{
                completion(.invalidData)
            }
        }
    }
}

class HTTPClient{
    var requestedLoadCallCount = 0
    var completions = [(Data?, Error?) -> Void]()
    
    func getRepos(completion: @escaping (Data?, Error?) -> Void){
        requestedLoadCallCount += 1
        completions.append(completion)
    }
    
    func completeWith(error: NSError, at index: Int = 0){
        completions[index](nil, error)
    }
    
    func completeWith(data: Data, at index: Int = 0){
        completions[index](data, nil)
    }
}

final class GitLoaderTests: XCTestCase {

    func test_init_doesnotRequetsGitHubRepos(){
        let (_, client) = makeSUT()
        XCTAssertEqual(client.requestedLoadCallCount, 0)
    }
    
    
    func test_load_callsClientToGetReposFromURL(){
        let (sut, client) = makeSUT()
        sut.load(){_ in}
        XCTAssertEqual(client.requestedLoadCallCount, 1)
    }
    
    
    func test_load_failsWithNoConnectivityErrorOnClientFailingWithError(){
        let (sut, client) = makeSUT()
        sut.load(){ error in
            XCTAssertEqual(error, .noConnectivity)
        }
        client.completeWith(error: anyError())
        
    }
    
    func test_load_failsWithInvalidDataError(){
        let (sut, client) = makeSUT()
        sut.load(){ error in
            XCTAssertEqual(error, .invalidData)
        }
        let data = Data.init("Invalid data".utf8)
        client.completeWith(data: data)

    }
    
    
    
    
    
    private func makeSUT() -> (RemoteGitLoader, HTTPClient){
        let client = HTTPClient()
        let sut = RemoteGitLoader(client: client)
        return (sut, client)
    }
    
    private func anyError() -> NSError{
        NSError(domain: "some error domain", code: 41)
    }
}
