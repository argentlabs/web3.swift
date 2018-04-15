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
    var erc20: ERC20?
    let testContractAddress = EthereumAddress(TestConfig.erc20Contract)
    
    override func setUp() {
        super.setUp()
        let client = EthereumClient(url: URL(string: TestConfig.clientUrl)!)
        self.erc20 = ERC20(client: client)
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testName() {
        let expect = expectation(description: "Get token name")
        erc20?.name(tokenContract: self.testContractAddress, completion: { (error, name) in
            XCTAssertNil(error)
            XCTAssert(name == "BokkyPooBah Test Token")
            expect.fulfill()
        })
        waitForExpectations(timeout: 10)
    }
    
    func testDecimals() {
        let expect = expectation(description: "Get token decimals")
        erc20?.decimals(tokenContract: self.testContractAddress, completion: { (error, decimals) in
            XCTAssertNil(error)
            XCTAssert(decimals == BigUInt(18))
            expect.fulfill()
        })
        waitForExpectations(timeout: 10)
    }
    
    func testSymbol() {
        let expect = expectation(description: "Get token symbol")
        erc20?.symbol(tokenContract: self.testContractAddress, completion: { (error, symbol) in
            XCTAssertNil(error)
            XCTAssert(symbol == "BOKKY")
            expect.fulfill()
        })
        waitForExpectations(timeout: 10)
    }
    
}
