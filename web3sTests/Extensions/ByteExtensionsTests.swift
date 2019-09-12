//
//  ByteExtensionsTests.swift
//  web3sTests
//
//  Created by Matt Marshall on 14/03/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import XCTest
import BigInt
@testable import web3swift

class ByteExtensionsTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testBytesFromBigInt() {
        XCTAssertEqual(BigInt(3251).bytes, [12, 179])
        XCTAssertEqual(BigInt(434350411044).bytes, [101, 33, 77, 77, 36])
        XCTAssertEqual(BigInt(-404).bytes, [254, 108])
    }
    
    func testBigIntFromTwosComplement() {
        let bytes: [UInt8] = [3, 0, 24, 124, 109]
        let data = Data(bytes)
        let bint = BigInt(twosComplement: data)
        
        XCTAssertEqual(bint, 12886506605)
    }
    
    func testBytesFromData() {
        let bytes: [UInt8] = [255, 0, 123, 64]
        let data = Data(bytes)
        XCTAssertEqual(data.bytes, bytes)
    }
    
    func testStrippingZeroesFromBytes() {
        let bytes: [UInt8] = [0, 0, 0, 24, 124, 109]
        let data = Data(bytes)
        
        let stripped = data.strippingZeroesFromBytes
        XCTAssertEqual([24, 124, 109], stripped.bytes)
    }
    
    func testStrippingZeroesFromBytesNone() {
        let bytes: [UInt8] = [3, 0, 24, 124, 109]
        let data = Data(bytes)
        
        let stripped = data.strippingZeroesFromBytes
        XCTAssertEqual([3, 0, 24, 124, 109], stripped.bytes)
    }
    
    func testBytesFromString() {
        let str = "hello world"
        XCTAssertEqual(str.bytes, [104, 101, 108, 108, 111, 32, 119, 111, 114, 108, 100])
    }
    
    func testBytesFromHex() {
        let hex = "0x68656c6c6f20776f726c64"
        XCTAssertEqual(hex.bytesFromHex!, [104, 101, 108, 108, 111, 32, 119, 111, 114, 108, 100])
    }
    
    func testHexFromBytes() {
        let bytes: [UInt8] = [104, 101, 108, 108, 111, 32, 119, 111, 114, 108, 100]
        let str = String(hexFromBytes: bytes)
        XCTAssertEqual(str, "0x68656c6c6f20776f726c64")
    }
    
    
    func test_GivenEqualSizeData_XorIsCorrect() {
        let dataA = "932545426104aec98a84b11f89010e409615d4e118552c694c4a726f29caf77a".hexData!
        
        let dataB = "c87b56dda752230262935940d907f047a9f86bb5ee6aa33511fc86db33fea6cc".hexData!
        
        let result = dataA ^ dataB
        XCTAssertEqual(result.hexString, "0x5b5e139fc6568dcbe817e85f5006fe073fedbf54f63f8f5c5db6f4b41a3451b6")
    }
    
    func test_GivenDifferentSizeData_XorIsCutToSmallest() {
        let dataA = "932545426104aec98a84b11f89010e409615d4e118552c694c4a726f29caf7".hexData!
        
        let dataB = "c87b56dda752230262935940d907f047a9f86bb5ee6aa33511fc86db33fea6cc".hexData!
        
        let result = dataA ^ dataB
        XCTAssertEqual(result.hexString, "0x5b5e139fc6568dcbe817e85f5006fe073fedbf54f63f8f5c5db6f4b41a3451")
    }
    
}

