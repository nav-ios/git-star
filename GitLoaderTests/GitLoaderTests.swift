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
    init(client: HTTPClient) {
        self.client = client
    }
    
    func load(){
        client.requestedLoadCallCount = 1
    }
}

class HTTPClient{
    var requestedLoadCallCount = 0
}

final class GitLoaderTests: XCTestCase {

    func test_init_doesnotRequetsGitHubRepos(){
        let (_, client) = makeSUT()
        XCTAssertEqual(client.requestedLoadCallCount, 0)
    }
    
    
    func test_load_callsClientToGetReposFromURL(){
        let (sut, client) = makeSUT()
        sut.load()
        XCTAssertEqual(client.requestedLoadCallCount, 1)
    }
    
    
    
    private func makeSUT() -> (RemoteGitLoader, HTTPClient){
        let client = HTTPClient()
        let sut = RemoteGitLoader(client: client)
        return (sut, client)
    }
}
