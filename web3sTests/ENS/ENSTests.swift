//
//  ENSTests.swift
//  web3sTests
//
//  Created by Matt Marshall on 13/03/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import XCTest
@testable import web3swift

class ENSTests: XCTestCase {
    var client: EthereumClient?
    var account: EthereumAccount?
    
    override func setUp() {
        super.setUp()
        self.client = EthereumClient(url: URL(string: TestConfig.clientUrl)!)
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testNameHash() {
        let name = "argent.test"
        let nameHash = EthereumNameService.nameHash(name: name)
        XCTAssert(nameHash == "0x3e58ef7a2e196baf0b9d36a65cc590ac9edafb3395b7cdeb8f39206049b4534c")
    }
    
    func testOwner() {
        let expect = expectation(description: "Get the ENS owner")
        
        do {
            let contract = ENSRegistryContract(chainId: EthereumNetwork.Ropsten.intValue)
            let tx = try contract?.owner(name: "test")
            
            client?.eth_call(tx!, block: .Latest, completion: { (error, dataStr) in
                let owner = String(dataStr![dataStr!.index(dataStr!.endIndex, offsetBy: -40)...])
                XCTAssertEqual(owner.noHexPrefix,"21397c1a1f4acd9132fe36df011610564b87e24b")
                expect.fulfill()
            })
            
        } catch {
            XCTFail()
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 20)
    }
    
    func testResolveAddress() {
        let expect = expectation(description: "Get the ENS address")
        
        let nameService = EthereumNameService(client: client!)
        nameService.resolve(address: EthereumAddress("0xb0b874220ff95d62a676f58d186c832b3e6529c8"), completion: { (error, ens) in
            XCTAssert("julien.argent.test" == ens)
            expect.fulfill()
        })
        
        waitForExpectations(timeout: 20)
    }
    
    func testResolveAlias() {
        let expect = expectation(description: "Get the ENS reverse lookup address")
        
        let nameService = EthereumNameService(client: client!)
        nameService.resolve(ens: "julien.argent.test", completion: { (error, ens) in
            XCTAssert("0xb0b874220ff95d62a676f58d186c832b3e6529c8" == ens)
            expect.fulfill()
        })
        
        waitForExpectations(timeout: 20)
    }
    
}
