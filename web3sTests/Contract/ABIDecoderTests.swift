//
//  ABIDecoderTests.swift
//  web3swiftTests
//
//  Created by Matt Marshall on 20/03/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import XCTest
import BigInt
@testable import web3swift

class ABIDecoderTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testDecodeUint32() {
        do {
            let decoded = try ABIDecoder.decodeData("0x000000000000000000000000000000000000000000000000000000000000002a", types: ["uint32"]) as! [String]
            XCTAssert(BigInt(hex: decoded[0]) == 42)
        } catch let error {
            print(error.localizedDescription)
            XCTFail()
        }
    }
    
    func testDecodeUint256Array() {
        do {
            let decoded = try ABIDecoder.decodeData("0x00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000003", types: ["uint256[]"]) as! [[String]]
            let result = decoded[0].map {
                return BigInt(hex: $0)!
            }
            XCTAssert(result == [BigInt(1), BigInt(2), BigInt(3)])
        } catch let error {
            print(error.localizedDescription)
            XCTFail()
        }
    }
    
    func testDecodeAddress() {
        do {
            let decoded = try ABIDecoder.decodeData("0x00000000000000000000000021397c1a1f4acd9132fe36df011610564b87e24b", types: ["address"]) as! [String]
            XCTAssert(decoded[0] == "0x21397c1a1f4acd9132fe36df011610564b87e24b")
        } catch let error {
            print(error.localizedDescription)
            XCTFail()
        }
        
    }
    
    func testDecodeString() {
        do {
            let decoded = try ABIDecoder.decodeData("0x000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000147665726f6e696b612e617267656e742e74657374000000000000000000000000", types: ["string"]) as! [String]
            XCTAssert(decoded[0].stringValue == "veronika.argent.test")
        } catch let error {
            print(error.localizedDescription)
            XCTFail()
        }
        
    }
    
    func testDecodeAddressArray() {
        do {
            let decoded = try ABIDecoder.decodeData("0x000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a77b0f3aae325cb2ec1bdb4a3548d816a83b8ca3", types: ["address[]"]) as! [[String]]
            XCTAssert(decoded[0] == ["0x0000000000000000000000000000000000000000", "0xa77b0f3aae325cb2ec1bdb4a3548d816a83b8ca3"])
        } catch let error {
            print(error.localizedDescription)
            XCTFail()
        }
        
    }
    
    func testDecodeFixedBytes1() {
        do {
            let decoded = try ABIDecoder.decodeData("0x0000000000000000000000000000000000000000000000000000000000000063", types: [.FixedBytes(1)]) as! [String]
            XCTAssertEqual(decoded.first, "0x63")
        } catch let error {
            print(error.localizedDescription)
            XCTFail()
        }
    }
    
    func testDecodeFixedBytes3() {
        do {
            let decoded = try ABIDecoder.decodeData("0x0000000000000000000000000000000000000000000000000000000000616263", types: [.FixedBytes(3)]) as! [String]
            XCTAssertEqual(decoded.first, "0x616263")
        } catch let error {
            print(error.localizedDescription)
            XCTFail()
        }
    }
    
    func testDecodeFixedBytes32() {
        do {
            let decoded = try ABIDecoder.decodeData("0x0200000000000000000000000050000000000000000000000000000000616263", types: [.FixedBytes(32)]) as! [String]
            XCTAssertEqual(decoded.first, "0x0200000000000000000000000050000000000000000000000000000000616263")
        } catch let error {
            print(error.localizedDescription)
            XCTFail()
        }
    }
}
