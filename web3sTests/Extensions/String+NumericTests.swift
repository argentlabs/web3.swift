//
//  String+NumericTests.swift
//  web3sTests
//
//  Created by Matt Marshall on 13/03/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import XCTest
@testable import web3swift

class String_NumericTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testStringNumeric() {
        XCTAssertTrue("493043".isNumeric)
        XCTAssertTrue("12".isNumeric)
        XCTAssertTrue("0".isNumeric)
        XCTAssertTrue("98420342842".isNumeric)
        XCTAssertTrue("493204385594385034583409583490583".isNumeric)
        
        XCTAssertFalse("0x00".isNumeric)
        XCTAssertFalse("hello world".isNumeric)
        XCTAssertFalse("!9043".isNumeric)
        XCTAssertFalse("#42044".isNumeric)
    }
    
}
