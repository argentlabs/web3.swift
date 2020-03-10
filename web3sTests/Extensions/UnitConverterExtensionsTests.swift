//
//  UnitConverterTests.swift
//  web3swift
//
//  Created by Philippe Mercier on 09/03/2020.
//  Copyright © 2020 Argent Labs Limited. All rights reserved.
//

import XCTest
import BigInt
@testable import web3swift

class UnitConverterExtensionsTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testEtherToWei() {
        XCTAssertEqual(BigUInt(1).web3.toWei, BigUInt(1_000_000_000_000_000_000))
    }
    
    func testEtherToGwei() {
        XCTAssertEqual(BigUInt(1).web3.toGwei, BigUInt(1_000_000_000))
    }
}

