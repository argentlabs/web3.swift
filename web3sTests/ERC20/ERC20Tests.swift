//
//  ERC20Tests.swift
//  web3swiftTests
//
//  Created by Matt Marshall on 13/04/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import XCTest
import BigInt
@testable import web3swift

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
            XCTAssertEqual(decimals, BigUInt(18))
            expect.fulfill()
        })
        waitForExpectations(timeout: 10)
    }
    
    func testZeroDecimals() {
        let expect = expectation(description: "Get token decimals (0)")
        erc20?.decimals(tokenContract: EthereumAddress("0x40dd3ac2481960cf34d96e647dd0bc52a1f03f52"), completion: { (error, decimals) in
            XCTAssertNil(error)
            XCTAssertEqual(decimals, BigUInt(0))
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
    
    func testTotalSupply() {
        let expect = expectation(description: "Get total supply")
        erc20?.totalSupply(tokenContract: EthereumAddress("0x820e5885a15234258cdb40c5911884232c70f3b5") /* Fixed Supply Token */, completion: { (error, totalSupply) in
            XCTAssertNil(error)
            XCTAssertEqual(totalSupply, BigUInt(1_000_000_000).web3.toWei)
            expect.fulfill()
        })
        waitForExpectations(timeout: 10)
    }
    
    func testTransferRawEvent() {
        let expect = expectation(description: "Get transfer event")
        
        let result = try! ABIEncoder.encode("0x72e3b687805ef66bf2a1e6d9f03faf8b33f0267a", forType: ABIRawType(type: EthereumAddress.self)!)
        let sig = try! ERC20Events.Transfer.signature()
        let topics = [ sig, String(hexFromBytes: result)]
    
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
    
    func testApprovalEventsForSpender() {
        let expect = expectation(description: "Get approval events for a specific spender")

        erc20?.approvalEvents(owner: nil, spender: EthereumAddress("0x1533a22e8a22366c5516d317af5663e1ca769fe7"), fromBlock: EthereumBlock(rawValue: 4612800), toBlock: EthereumBlock(rawValue: 4613000), completion: { (error, events) in
            XCTAssert(events!.count > 0)
            expect.fulfill()
        })
        
        waitForExpectations(timeout: 10)
    }
    
    func testApprovalEventsForOwner() {
        let expect = expectation(description: "Get approval events for a specific owner")

        erc20?.approvalEvents(owner: EthereumAddress("0xb5505ae3835fa24c2b3a62a58cea27e4d62b4195"), spender: nil, fromBlock: EthereumBlock(rawValue: 4612800), toBlock: EthereumBlock(rawValue: 4613000), completion: { (error, events) in
            XCTAssert(events!.count == 4)
            expect.fulfill()
        })
        
        waitForExpectations(timeout: 10)
    }
    
    func testApprovalEventsForOwnerAndSpender() {
        let expect = expectation(description: "Get approval events for a specific owner & spender")
        
        erc20?.approvalEvents(owner: EthereumAddress("0xb5505ae3835fa24c2b3a62a58cea27e4d62b4195"), spender: EthereumAddress("0x502e2806f64bf676601f4f5810b02e2331f14037"), fromBlock: EthereumBlock(rawValue: 4612800), toBlock: EthereumBlock(rawValue: 4613000), completion: { (error, events) in
            XCTAssert(events!.count == 2)
            expect.fulfill()
        })
        
        waitForExpectations(timeout: 10)
    }
    
    func testApprovalEventsAll() {
        let expect = expectation(description: "Get all approval events")
        
        erc20?.approvalEvents(owner: nil, spender: nil, fromBlock: EthereumBlock(rawValue: 4612800), toBlock: EthereumBlock(rawValue: 4613000), completion: { (error, events) in
            XCTAssert(events!.count == 29)
            expect.fulfill()
        })
        
        waitForExpectations(timeout: 10)
    }
    
}
