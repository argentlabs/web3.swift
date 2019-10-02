//
//  HexExtensionsTests.swift
//  web3sTests
//
//  Created by Matt Marshall on 14/03/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import XCTest
import BigInt
@testable import web3swift

class HexExtensionsTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testIntToHexString() {
        XCTAssertEqual(0.hexString, "0x0")
        XCTAssertEqual(8.hexString, "0x8")
        XCTAssertEqual(453504.hexString, "0x6eb80")
    }
    
    func testIntFromHexString() {
        XCTAssertEqual(Int(hex: ""), nil)
        XCTAssertEqual(Int(hex: "0x0")!, 0)
        XCTAssertEqual(Int(hex: "0x10")!, 16)
        XCTAssertEqual(Int(hex: "0x8f9f31")!, 9412401)
    }
    
    func testBigUIntFromHexStringEmpty() {
        XCTAssertEqual(BigUInt(hex: "")!, 0)
        XCTAssertEqual(BigUInt(hex: "0x0")!, 0)
        XCTAssertEqual(BigUInt(hex: "0x10")!, 16)
        XCTAssertEqual(BigUInt(hex: "0x8f9f31")!, 9412401)
        XCTAssertEqual(BigUInt(hex: "0x2A521C551E7F200D")!, 3049531049592692749)
    }
    
    func testBigIntFromHexString() {
        XCTAssertEqual(BigInt(hex: "")!, 0)
        XCTAssertEqual(BigInt(hex: "0x0")!, 0)
        XCTAssertEqual(BigInt(hex: "0x10")!, 16)
        XCTAssertEqual(BigInt(hex: "0x8f9f31")!, 9412401)
        XCTAssertEqual(BigInt(hex: "0x2A521C551E7F200D")!, 3049531049592692749)
    }
    
    func testDataToHexString() {
        let string = "0x68656c6c6f20776f726c64"
        let data = string.hexData!
        let dataToHex = data.hexString
        XCTAssertEqual(dataToHex, string)
    }
    
    func testDataToHexStringFromBytes() {
        let data = Data( [43, 111])
        let hexString = data.hexString
        XCTAssertEqual(hexString, "0x2b6f")
    }
    
    func testDataToHexStringRandom() {
        let data = Data.randomOfLength(8)!
        XCTAssertEqual(data.hexString.count, 18)
    }
    
    func testDataFromHexString() {
        let string = "0x68656c6c6f20776f726c64"
        let data = Data(hex: string)
        XCTAssertNotNil(data)
    }
    
    func testDataFromHexStringFail() {
        let string = "random str"
        let data = Data(hex: string)
        XCTAssertEqual(data, nil)
    }
    
    func testNoHexPrefixWith() {
        let string = "0x427131"
        XCTAssertEqual(string.noHexPrefix, "427131")
    }
    
    func testNoHexPrefixWithout() {
        let string = "427131"
        XCTAssertEqual(string.noHexPrefix, string)
    }
    
    func testHexStringToData() {
        let hexString = "2b6f"
        let data = hexString.hexData
        XCTAssertEqual(data, Data( [43, 111]))
    }
    
    func testHexStringToDataPrefix() {
        let hexString = "0x2b6f"
        let data = hexString.hexData
        XCTAssertEqual(data, Data( [43, 111]))
    }
    
    func testHexStringFromBytes() {
        let string = String(bytes: [43, 111])
        XCTAssertEqual(string, "0x2b6f")
    }
    
    func testHexStringToUTF8() {
        let hex = "0x68656c6c6f20776f726c64"
        XCTAssertEqual(hex.stringValue, "hello world")
    }
}

