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
    }
    
    init(client: HTTPClient) {
        self.client = client
    }
    
    func load(completion: @escaping (Error) -> Void){
        client.getRepos(){ error in
            completion(.noConnectivity)
        }
    }
}

class HTTPClient{
    var requestedLoadCallCount = 0
    
    func getRepos(completion: @escaping (Error) -> Void){
        requestedLoadCallCount += 1
        completion(NSError(domain: "anyError", code: 404))
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
        let (sut, _) = makeSUT()
        sut.load(){ error in
            XCTAssertEqual(error, .noConnectivity)
        }
    }
    
    
    
    private func makeSUT() -> (RemoteGitLoader, HTTPClient){
        let client = HTTPClient()
        let sut = RemoteGitLoader(client: client)
        return (sut, client)
    }
}
