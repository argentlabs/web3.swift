//
//  ERC20Tests.swift
//  web3swiftTests
//
//  Created by Matt Marshall on 13/04/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import XCTest
import BigInt
@testable import web3

class ERC20Tests: XCTestCase {
    var client: EthereumClient?
    var erc20: ERC20?
    let testContractAddress = EthereumAddress(TestConfig.erc20Contract)
    
    override func setUp() {
        super.setUp()
        self.client = EthereumClient(url: URL(string: TestConfig.clientUrl)!)
        self.erc20 = ERC20(client: client!)
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testName() {
        let expect = expectation(description: "Get token name")
        erc20?.name(tokenContract: self.testContractAddress, completion: { (error, name) in
            XCTAssertNil(error)
            XCTAssertEqual(name, "BokkyPooBah Test Token")
            expect.fulfill()
        })
        waitForExpectations(timeout: 10)
    }
    
    func testNonZeroDecimals() {
        let expect = expectation(description: "Get token decimals")
        erc20?.decimals(tokenContract: self.testContractAddress, completion: { (error, decimals) in
            XCTAssertNil(error)
            XCTAssertEqual(decimals, 18)
            expect.fulfill()
        })
        waitForExpectations(timeout: 10)
    }
    
    func testZeroDecimals() {
        let expect = expectation(description: "Get token decimals (0)")
        erc20?.decimals(tokenContract: EthereumAddress("0x40dd3ac2481960cf34d96e647dd0bc52a1f03f52"), completion: { (error, decimals) in
            XCTAssertNil(error)
            XCTAssertEqual(decimals, 0)
            expect.fulfill()
        })
        waitForExpectations(timeout: 10)
    }
    
    func testSymbol() {
        let expect = expectation(description: "Get token symbol")
        erc20?.symbol(tokenContract: self.testContractAddress, completion: { (error, symbol) in
            XCTAssertNil(error)
            XCTAssertEqual(symbol, "BOKKY")
            expect.fulfill()
        })
        waitForExpectations(timeout: 10)
    }
    
    func testTransferRawEvent() {
        let expect = expectation(description: "Get transfer event")
        
        let result = try! ABIEncoder.encode(EthereumAddress("0x72e3b687805ef66bf2a1e6d9f03faf8b33f0267a"))
        let sig = try! ERC20Events.Transfer.signature()
        let topics = [ sig, result.hexString]
    
        self.client?.getEvents(addresses: nil, topics: topics, fromBlock: .Earliest, toBlock: .Latest, eventTypes: [ERC20Events.Transfer.self], completion: { (error, events, unprocessed) in
            XCTAssert(events.count > 0)
            expect.fulfill()
        })
        waitForExpectations(timeout: 10)
    }
    
    func testTransferEventsTo() {
        let expect = expectation(description: "Get transfer events to")
        
        erc20?.transferEventsTo(recipient: EthereumAddress("0x72e3b687805ef66bf2a1e6d9f03faf8b33f0267a"), fromBlock: .Earliest, toBlock: .Latest, completion: { (error, events) in
            XCTAssert(events!.count > 0)
            expect.fulfill()
        })
        
        waitForExpectations(timeout: 10)
    }
    
}
