//
//  KeccakExtensionsTests.swift
//  web3sTests
//
//  Created by Matt Marshall on 13/03/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

@testable import web3
import XCTest

class KeccakExtensionsTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testKeccak256Hash() {
        let string = "hello world"
        let hash = string.web3.keccak256
        let hexStringHash = hash.web3.hexString
        XCTAssertEqual(hexStringHash, "0x47173285a8d7341e5e972fc677286384f802f8ef42a5ec5f03bbfa254cb01fad")
    }

    func testDataKeccak256HashHex() {
        let string = "0x68656c6c6f20776f726c64"
        let data = Data(hex: string)!
        let keccak = data.web3.keccak256
        XCTAssertEqual(keccak.web3.hexString, "0x47173285a8d7341e5e972fc677286384f802f8ef42a5ec5f03bbfa254cb01fad")
    }

    func testDataKeccak256HashStr() {
        let string = "hello world"
        let data = string.data(using: .utf8)!
        let keccak = data.web3.keccak256
        XCTAssertEqual(keccak.web3.hexString, "0x47173285a8d7341e5e972fc677286384f802f8ef42a5ec5f03bbfa254cb01fad")
    }

    func test_toChecksumAddress() {
        let val1 = "0x12ae66cdc592e10b60f9097a7b0d3c59fce29876"
        let val2 = "0x90f8bf6a479f320ead074411a4b0e7944ea8c9c1"
        XCTAssertEqual(val1.toChecksumAddress(), "0x12AE66CDc592e10B60f9097a7b0D3C59fce29876")
        XCTAssertEqual(val2.toChecksumAddress(), "0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1")
    }
}
