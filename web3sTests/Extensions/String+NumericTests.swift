//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import XCTest
@testable import web3

class String_NumericTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testStringNumeric() {
        XCTAssertTrue("493043".web3.isNumeric)
        XCTAssertTrue("12".web3.isNumeric)
        XCTAssertTrue("0".web3.isNumeric)
        XCTAssertTrue("98420342842".web3.isNumeric)
        XCTAssertTrue("493204385594385034583409583490583".web3.isNumeric)

        XCTAssertFalse("0x00".web3.isNumeric)
        XCTAssertFalse("hello world".web3.isNumeric)
        XCTAssertFalse("!9043".web3.isNumeric)
        XCTAssertFalse("#42044".web3.isNumeric)
    }

}
