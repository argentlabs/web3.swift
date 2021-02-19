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
    func testGivenSmallBigUInt_EncodesCorrectly() {
        let encoded = try? ABIEncoder.encode(BigUInt(10))
        XCTAssertEqual(encoded?.hexString, "0x000000000000000000000000000000000000000000000000000000000000000a")
    }
    
    func testGivenBigUInt_EncodesCorrectly() {
        let encoded = try? ABIEncoder.encode(BigUInt(10).power(20))
        XCTAssertEqual(encoded?.hexString, "0x0000000000000000000000000000000000000000000000056bc75e2d63100000")
    }
    
    func testGivenUInt32_EncodesCorrectly() {
        let encoded = try? ABIEncoder.encode(UInt32(25639))
        XCTAssertEqual(encoded?.hexString, "0x0000000000000000000000000000000000000000000000000000000000006427")
    }
    
    func testGivenNegativeInt32_EncodesCorrectly() {
        let encoded = try? ABIEncoder.encodeRaw("-25896", forType: ABIRawType.FixedInt(32))
        XCTAssertEqual(encoded?.hexString, "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff9ad8")
    }
    
    func testGivenShortString_EncodesCorrectly() {
        let encoded = try? ABIEncoder.encode("a response string (unsupported)")
        XCTAssertEqual(encoded?.hexString, "0x000000000000000000000000000000000000000000000000000000000000001f6120726573706f6e736520737472696e672028756e737570706f727465642900")
    }
    
    func testGivenLongString_EncodesCorrectly() {
        let encoded = try? ABIEncoder.encode(" hello world hello world hello world hello world  hello world hello world hello world hello world  hello world hello world hello world hello world hello world hello world hello world hello world")
        XCTAssertEqual(encoded?.hexString, "0x00000000000000000000000000000000000000000000000000000000000000c22068656c6c6f20776f726c642068656c6c6f20776f726c642068656c6c6f20776f726c642068656c6c6f20776f726c64202068656c6c6f20776f726c642068656c6c6f20776f726c642068656c6c6f20776f726c642068656c6c6f20776f726c64202068656c6c6f20776f726c642068656c6c6f20776f726c642068656c6c6f20776f726c642068656c6c6f20776f726c642068656c6c6f20776f726c642068656c6c6f20776f726c642068656c6c6f20776f726c642068656c6c6f20776f726c64000000000000000000000000000000000000000000000000000000000000")
    }
    
    func testGivenAddress_EncodesCorrectly() {
        let encoded = try? ABIEncoder.encode(EthereumAddress("0x407d73d8a49eeb85d32cf465507dd71d507100c1"))
        XCTAssertEqual(encoded?.hexString, "0x000000000000000000000000407d73d8a49eeb85d32cf465507dd71d507100c1")
    }
    
    func testGivenTrue_EncodesCorrectly() {
        let encoded = try? ABIEncoder.encode(true)
        XCTAssertEqual(encoded?.hexString, "0x0000000000000000000000000000000000000000000000000000000000000001")
    }
    
    func testGivenFalse_EncodesCorrectly() {
        let encoded = try? ABIEncoder.encode(false)
        XCTAssertEqual(encoded?.hexString, "0x0000000000000000000000000000000000000000000000000000000000000000")
    }
    
    func testGivenBytes1_EncodesCorrectly() {
        let encoded = try? ABIEncoder.encode("0x63".web3.hexData!, staticSize: 1)
        XCTAssertEqual(encoded?.hexString,
                       "0x6300000000000000000000000000000000000000000000000000000000000000")
    }
    
    func testGivenBytes3_EncodesCorrectly() {
        let encoded = try? ABIEncoder.encode("0x616263".web3.hexData!, staticSize: 3)
        XCTAssertEqual(encoded?.hexString, "0x6162630000000000000000000000000000000000000000000000000000000000")
    }
    
    func testGivenBytes32_EncodesCorrectly() {
        let encoded = try? ABIEncoder.encode("0x0200000000000000000000000050000000000000000000000000000000616263".web3.hexData!, staticSize: 32)
        XCTAssertEqual(encoded?.hexString, "0x0200000000000000000000000050000000000000000000000000000000616263")
    }
    
    func testGivenDynamicBytes_EncodesCorrectly() {
        let encoded = try? ABIEncoder.encode("0x01010101aabbccdd9988776678947894".web3.hexData!)
        XCTAssertEqual(encoded?.hexString, "0x000000000000000000000000000000000000000000000000000000000000001001010101aabbccdd998877667894789400000000000000000000000000000000")
    }
    
    func testGivenDynamicBytesArray_EncodesCorrectly() {
        let encoded = try? ABIEncoder.encode(["0x01010101aabbccdd9988776678947894".web3.hexData!, "0x1235566666600980".web3.hexData!])
        XCTAssertEqual(encoded?.hexString, "0x000000000000000000000000000000000000000000000000000000000000001001010101aabbccdd99887766789478940000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000081235566666600980000000000000000000000000000000000000000000000000")
    }
    
    func testGivenSmallDynamicBytes4Array_EncodesCorrectly() {
        let encoded = try? ABIEncoder.encodeRaw("0x01010101aabbccdd9988776678947894", forType: ABIRawType.DynamicArray(ABIRawType.FixedBytes(4)))
        XCTAssertEqual(encoded?.hexString, "0x000000000000000000000000000000000000000000000000000000000000000401010101aabbccdd998877667894789400000000000000000000000000000000")
    }
    
    func testGivenBigDynamicBytes4Array_EncodesCorrectly() {
        let encoded = try? ABIEncoder.encodeRaw("0x01010101aabbccdd99887766789478941234567891011121314151617181920212223443", forType: ABIRawType.DynamicArray(ABIRawType.FixedBytes(4)))
        XCTAssertEqual(encoded?.hexString, "0x000000000000000000000000000000000000000000000000000000000000000901010101aabbccdd9988776678947894123456789101112131415161718192021222344300000000000000000000000000000000000000000000000000000000")
    }
    
    func testGivenBigUIntArray_EncodesCorrectly() {
        let encoded = try? ABIEncoder.encode([BigUInt(2000), BigUInt(9098055), BigUInt(99999)])
        XCTAssertEqual(encoded?.hexString, "0x00000000000000000000000000000000000000000000000000000000000007d000000000000000000000000000000000000000000000000000000000008ad347000000000000000000000000000000000000000000000000000000000001869f")
    }
    
    func testGivenStringArray_EncodesCorrectly() {
        let encoded = try? ABIEncoder.encode(["hello", "big", "world"])
        XCTAssertEqual(encoded?.hexString, "0x000000000000000000000000000000000000000000000000000000000000000568656c6c6f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000362696700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005776f726c64000000000000000000000000000000000000000000000000000000")
    }
    
}
