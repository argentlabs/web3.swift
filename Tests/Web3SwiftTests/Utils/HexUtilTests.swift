//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import XCTest
@testable import web3

class HexUtilTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testByteArray() {
        guard let array = try? HexUtil.byteArray(fromHex: "") else { return XCTFail() }
        XCTAssertEqual(array, [])

        guard let array1 = try? HexUtil.byteArray(fromHex: "00") else { return XCTFail() }
        XCTAssertEqual(array1, [0])

        guard let array2 = try? HexUtil.byteArray(fromHex: "B6AB541600") else { return XCTFail() }
        XCTAssertEqual(array2, [182, 171, 84, 22, 0])

        guard let array3 = try? HexUtil.byteArray(fromHex: "68656c6c6f20776f726c6421") else { return XCTFail() }
        XCTAssertEqual(array3, [104, 101, 108, 108, 111, 32, 119, 111, 114, 108, 100, 33])
    }

    func testByteArrayFail() {
        do {
            _ = try HexUtil.byteArray(fromHex: "B6AB54160")
        } catch {
            XCTAssertEqual(error as? HexConversionError, HexConversionError.stringNotEven)
        }
    }

}
