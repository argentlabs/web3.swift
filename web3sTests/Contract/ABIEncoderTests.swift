//
//  ABIEncoderTests.swift
//  web3sTests
//
//  Created by Matt Marshall on 13/03/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import XCTest
import BigInt
@testable import web3swift

class ABIEncoderTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testEncodePositiveInt32() {
        var encoded: [UInt8]
        do {
            encoded = try ABIEncoder.encode("10000", forType: ABIRawType.FixedInt(32))
            XCTAssertEqual(String(hexFromBytes: encoded), "0x0000000000000000000000000000000000000000000000000000000000002710")
            encoded = try ABIEncoder.encode("25639", forType: ABIRawType.FixedInt(32))
            XCTAssertEqual(String(hexFromBytes: encoded), "0x0000000000000000000000000000000000000000000000000000000000006427")
        } catch let error {
            print(error.localizedDescription)    
            XCTFail()
        }
    }
 
    func testEncodeNegativeInt32() {
        
        do {
            let encoded = try ABIEncoder.encode("-25896", forType: ABIRawType.FixedInt(32))
            XCTAssertEqual(String(hexFromBytes: encoded), "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff9ad8")
        } catch let error {
            print(error.localizedDescription)
            XCTFail()
        }
    }
    
    func testEncodeSmallString() {
        
        do {
            let encoded = try ABIEncoder.encode("a response string (unsupported)", forType: ABIRawType.DynamicString)
            XCTAssertEqual(String(hexFromBytes: encoded), "0x000000000000000000000000000000000000000000000000000000000000001f6120726573706f6e736520737472696e672028756e737570706f727465642900")
        } catch let error {
            print(error.localizedDescription)
            XCTFail()
        }
    }
    
    func testEncodeLargeString() {
        
        do {
            let encoded = try ABIEncoder.encode(" hello world hello world hello world hello world  hello world hello world hello world hello world  hello world hello world hello world hello world hello world hello world hello world hello world", forType: ABIRawType.DynamicString)
            XCTAssertEqual(String(hexFromBytes: encoded), "0x00000000000000000000000000000000000000000000000000000000000000c22068656c6c6f20776f726c642068656c6c6f20776f726c642068656c6c6f20776f726c642068656c6c6f20776f726c64202068656c6c6f20776f726c642068656c6c6f20776f726c642068656c6c6f20776f726c642068656c6c6f20776f726c64202068656c6c6f20776f726c642068656c6c6f20776f726c642068656c6c6f20776f726c642068656c6c6f20776f726c642068656c6c6f20776f726c642068656c6c6f20776f726c642068656c6c6f20776f726c642068656c6c6f20776f726c64000000000000000000000000000000000000000000000000000000000000")
        } catch let error {
            print(error.localizedDescription)
            XCTFail()
        }
    }
    
    func testEncodeAddress() {
        
        do {
            let encoded = try ABIEncoder.encode("0x407d73d8a49eeb85d32cf465507dd71d507100c1", forType: ABIRawType.FixedAddress)
            XCTAssertEqual(String(hexFromBytes: encoded), "0x000000000000000000000000407d73d8a49eeb85d32cf465507dd71d507100c1")
        } catch let error {
            print(error.localizedDescription)
            XCTFail()
        }
    }
    
    func testEncodeBytes1() {
        
        do {
            let encoded = try ABIEncoder.encode("0x63", forType: ABIRawType.FixedBytes(1))
            XCTAssertEqual(String(hexFromBytes: encoded),
             "0x6300000000000000000000000000000000000000000000000000000000000000")
        } catch let error {
            print(error.localizedDescription)
            XCTFail()
        }
    }
    
    func testEncodeBytes3() {
        
        do {
            let encoded = try ABIEncoder.encode("0x616263", forType: ABIRawType.FixedBytes(3))
            XCTAssertEqual(String(hexFromBytes: encoded), "0x6162630000000000000000000000000000000000000000000000000000000000")
        } catch let error {
            print(error.localizedDescription)
            XCTFail()
        }
    }
    
    func testEncodeBytes32() {
        
        do {
            let encoded = try ABIEncoder.encode("0x0200000000000000000000000050000000000000000000000000000000616263", forType: ABIRawType.FixedBytes(32))
            XCTAssertEqual(String(hexFromBytes: encoded), "0x0200000000000000000000000050000000000000000000000000000000616263")
        } catch let error {
            print(error.localizedDescription)
            XCTFail()
        }
    }
    
    func testEncodeSmallDynamicBytes4Array() {
        
        do {
            let encoded = try ABIEncoder.encode("0x01010101aabbccdd9988776678947894", forType: ABIRawType.DynamicArray(ABIRawType.FixedBytes(4)))
            XCTAssertEqual(String(hexFromBytes: encoded), "0x000000000000000000000000000000000000000000000000000000000000000401010101aabbccdd998877667894789400000000000000000000000000000000")
        } catch let error {
            print(error.localizedDescription)
            XCTFail()
        }
    }
    
    func testEncodeBigDynamicBytes4Array() {
        
        do {
            let encoded = try ABIEncoder.encode("0x01010101aabbccdd99887766789478941234567891011121314151617181920212223443", forType: ABIRawType.DynamicArray(ABIRawType.FixedBytes(4)))
            XCTAssertEqual(String(hexFromBytes: encoded), "0x000000000000000000000000000000000000000000000000000000000000000901010101aabbccdd9988776678947894123456789101112131415161718192021222344300000000000000000000000000000000000000000000000000000000")
        } catch let error {
            print(error.localizedDescription)
            XCTFail()
        }
    }
}
