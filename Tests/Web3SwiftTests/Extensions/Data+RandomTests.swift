//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import XCTest
@testable import web3

class Data_RandomTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testRandomData16() {
        let data = Data.randomOfLength(16)!
        XCTAssertEqual(data.count, 16)
    }

    func testRandomData32() {
        let data = Data.randomOfLength(32)!
        XCTAssertEqual(data.count, 32)
    }

}
