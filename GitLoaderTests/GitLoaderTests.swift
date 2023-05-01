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
    
    public enum RemoteGitLoaderResult{
        case success([GitRepo])
        case failure(RemoteGitLoader.Error)
    }
    
    init(client: HTTPClient) {
        self.client = client
    }
    
    func load(completion: @escaping (RemoteGitLoaderResult) -> Void){
        client.getRepos(){ result in
            switch result{
            case let .success(data, response):
                if response.statusCode == 200{
                    do{
                        if let repos = try? JSONDecoder().decode([GitRepo].self, from: data){
                            completion(.success(repos))
                        }
                        
                    }catch{
                        completion(.failure(.invalidData))
                    }
                }else{
                    completion(.failure(.invalidData))
                }
            case let .failure(error):
                completion(.failure(.noConnectivity))
            }
        }
    }
}

class HTTPClient{
//    typealias Result = Swift.Result<(Data, HTTPURLResponse), Error>
    var requestedLoadCallCount = 0
    var completions = [(HTTPClientResult) -> Void]()
    
    enum HTTPClientResult{
        case success(Data, HTTPURLResponse)
        case failure(Error)
    }
    func getRepos(completion: @escaping (HTTPClientResult) -> Void){
        requestedLoadCallCount += 1
        completions.append(completion)
    }
    
    func completeWith(error: NSError, at index: Int = 0){
        completions[index](.failure(error))
    }
    
    func completeWith(data: Data, statusCode: Int, at index: Int = 0){
        let gitURL = URL(string: "https://api.github.com/search/repositories?q=created")!
        let response = HTTPURLResponse(url: gitURL, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
        completions[index](.success(data, response))
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
        let exp = expectation(description: "Wait for request from client")

        sut.load(){ result in
            switch result{
            case .success(_):
                XCTFail("Expected failure but got result?")
            case .failure(let error):
                XCTAssertEqual(error, .noConnectivity)
            }
            exp.fulfill()
        }
        client.completeWith(error: anyError())
        wait(for: [exp], timeout: 1.0)
    }


    func test_load_completesWithNon200StatusWithInvalidData(){
        let (sut, client) = makeSUT()
    
        let data = Data.init("Invalid data".utf8)
        let samplesNon200StatusCode = [199,201,202,204,500,501,502,504,404]
        
        let exp = expectation(description: "Wait for request from client")
        exp.expectedFulfillmentCount = samplesNon200StatusCode.count
        
        samplesNon200StatusCode.enumerated().forEach{ index, element in
            sut.load(){ result in
                switch result{
                case .success(_):
                    XCTFail("Expected failure but got result?")
                case .failure(let error):
                    XCTAssertNotNil(error)
                    XCTAssertEqual(error, .invalidData)
                }
                exp.fulfill()
            }
            client.completeWith(data: data, statusCode: element, at: index)
        }
        wait(for: [exp], timeout: 1.0)
    }

    
    
    private func makeSUT() -> (RemoteGitLoader, HTTPClient){
        let client = HTTPClient()
        let sut = RemoteGitLoader(client: client)
        return (sut, client)
    }
    
    private func anyError() -> NSError{
        NSError(domain: "some error domain", code: 41)
    }
    private func anyURL() -> URL{
        URL(string: "http://someurl.com")!
    }
    
    
}
