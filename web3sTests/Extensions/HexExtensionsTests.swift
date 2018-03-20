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
        XCTAssert(0.hexString == "0x0")
        XCTAssert(8.hexString == "0x8")
        XCTAssert(453504.hexString == "0x6eb80")
    }
    
    func testIntFromHexString() {
        XCTAssert(Int(hex: "") == nil)
        XCTAssert(Int(hex: "0x0")! == 0)
        XCTAssert(Int(hex: "0x10")! == 16)
        XCTAssert(Int(hex: "0x8f9f31")! == 9412401)
    }
    
    func testBigUIntFromHexStringEmpty() {
        XCTAssert(BigUInt(hex: "")! == 0)
        XCTAssert(BigUInt(hex: "0x0")! == 0)
        XCTAssert(BigUInt(hex: "0x10")! == 16)
        XCTAssert(BigUInt(hex: "0x8f9f31")! == 9412401)
        XCTAssert(BigUInt(hex: "0x2A521C551E7F200D")! == 3049531049592692749)
    }
    
    func testBigIntFromHexString() {
        XCTAssert(BigInt(hex: "")! == 0)
        XCTAssert(BigInt(hex: "0x0")! == 0)
        XCTAssert(BigInt(hex: "0x10")! == 16)
        XCTAssert(BigInt(hex: "0x8f9f31")! == 9412401)
        XCTAssert(BigInt(hex: "0x2A521C551E7F200D")! == 3049531049592692749)
    }
    
    func testDataToHexString() {
        let string = "0x68656c6c6f20776f726c64"
        let data = string.hexData!
        let dataToHex = data.hexString
        XCTAssert(dataToHex == string)
    }
    
    func testDataToHexStringFromBytes() {
        let data = Data(bytes: [43, 111])
        let hexString = data.hexString
        XCTAssert(hexString == "0x2b6f")
    }
    
    func testDataToHexStringRandom() {
        let data = Data.randomOfLength(8)!
        XCTAssert(data.hexString.count == 18)
    }
    
    func testDataFromHexString() {
        let string = "0x68656c6c6f20776f726c64"
        let data = Data(hex: string)
        XCTAssert(data != nil)
    }
    
    func testDataFromHexStringFail() {
        let string = "random str"
        let data = Data(hex: string)
        XCTAssert(data == nil)
    }
    
    func testNoHexPrefixWith() {
        let string = "0x427131"
        XCTAssert(string.noHexPrefix == "427131")
    }
    
    func testNoHexPrefixWithout() {
        let string = "427131"
        XCTAssert(string.noHexPrefix == string)
    }
    
    func testHexStringToData() {
        let hexString = "2b6f"
        let data = hexString.hexData
        XCTAssert(data == Data(bytes: [43, 111]))
    }
    
    func testHexStringToDataPrefix() {
        let hexString = "0x2b6f"
        let data = hexString.hexData
        XCTAssert(data == Data(bytes: [43, 111]))
    }
    
    func testHexStringFromBytes() {
        let string = String(bytes: [43, 111])
        XCTAssert(string == "0x2b6f")
    }
    
    func testHexStringToUTF8() {
        let hex = "0x68656c6c6f20776f726c64"
        XCTAssert(hex.stringValue == "hello world")
    }
}

