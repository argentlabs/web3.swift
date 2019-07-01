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
            XCTAssertEqual(BigInt(hex: decoded[0]), 42)
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
            XCTAssertEqual(result, [BigInt(1), BigInt(2), BigInt(3)])
        } catch let error {
            print(error.localizedDescription)
            XCTFail()
        }
    }
    
    func testDecodeAddress() {
        do {
            let decoded = try ABIDecoder.decodeData("0x00000000000000000000000021397c1a1f4acd9132fe36df011610564b87e24b", types: ["address"]) as! [String]
            XCTAssertEqual(decoded[0], "0x21397c1a1f4acd9132fe36df011610564b87e24b")
        } catch let error {
            print(error.localizedDescription)
            XCTFail()
        }
        
    }
    
    func testDecodeString() {
        do {
            let decoded = try ABIDecoder.decodeData("0x000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000147665726f6e696b612e617267656e742e74657374000000000000000000000000", types: ["string"]) as! [String]
            XCTAssertEqual(decoded[0].stringValue, "veronika.argent.test")
        } catch let error {
            print(error.localizedDescription)
            XCTFail()
        }
        
    }
    
    func testDecodeAddressArray() {
        do {
            let decoded = try ABIDecoder.decodeData("0x000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a77b0f3aae325cb2ec1bdb4a3548d816a83b8ca3", types: ["address[]"]) as! [[String]]
            XCTAssertEqual(decoded[0], ["0x0000000000000000000000000000000000000000", "0xa77b0f3aae325cb2ec1bdb4a3548d816a83b8ca3"])
        } catch let error {
            print(error.localizedDescription)
            XCTFail()
        }
        
    }
    
    func testDecodeFixedBytes1() {
        do {
            let decoded = try ABIDecoder.decodeData("0x0000000000000000000000000000000000000000000000000000000000000063", types: [.FixedBytes(1)])
            XCTAssertEqual(decoded[0].first, "0x63")
        } catch let error {
            print(error.localizedDescription)
            XCTFail()
        }
    }
    
    func testDecodeFixedBytes3() {
        do {
            let decoded = try ABIDecoder.decodeData("0x0000000000000000000000000000000000000000000000000000000000616263", types: [.FixedBytes(3)])
            XCTAssertEqual(decoded[0].first, "0x616263")
        } catch let error {
            print(error.localizedDescription)
            XCTFail()
        }
    }
    
    func testDecodeFixedBytes32() {
        do {
            let decoded = try ABIDecoder.decodeData("0x0200000000000000000000000050000000000000000000000000000000616263", types: [.FixedBytes(32)])
            XCTAssertEqual(decoded[0].first, "0x0200000000000000000000000050000000000000000000000000000000616263")
        } catch let error {
            print(error.localizedDescription)
            XCTFail()
        }
    }
    
    func testDecodeEmptyDynamicData() {
        do {
            let decoded = try ABIDecoder.decodeData("0x00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000", types: [.DynamicBytes])
            XCTAssertEqual(decoded[0].first, "")
        } catch let error {
            print(error.localizedDescription)
            XCTFail()
        }
    }
    
    func testDecodeDynamicData() {
        do {
            let decoded = try ABIDecoder.decodeData("0x0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000d48656c6c6f2c20776f726c642100000000000000000000000000000000000000", types: [.DynamicBytes])
                
            XCTAssertEqual(decoded[0].first, "0x48656c6c6f2c20776f726c6421")
        } catch let error {
            print(error.localizedDescription)
            XCTFail()
        }
    }
    
    func test_GivenSimpleURL_ThenDecodesCorrectly() {
        do {
            let decoded = try ABIDecoder.decode("68747470733a2f2f7777772e617267656e742e78797a", to: URL.self)
            XCTAssertEqual(decoded.absoluteString, "https://www.argent.xyz")
        } catch let error {
            print(error.localizedDescription)
            XCTFail()
        }
    }
    
    func test_GivenURLNullTermiated_ThenDecodesCorrectly() {
        do {
            let decoded = try ABIDecoder.decode("68747470733a2f2f7777772e617267656e742e78797a0000000000000000", to: URL.self)
            XCTAssertEqual(decoded.absoluteString, "https://www.argent.xyz")
        } catch let error {
            print(error.localizedDescription)
            XCTFail()
        }
    }
    
    func test_GivenLongerURLNullTerminated_ThenDecodesCorrectly() {
        do {
            let decoded = try ABIDecoder.decode("68747470733a2f2f7777772e63727970746f61746f6d732e6f72672f637265732f7572692f3333300000000000000000000000000000000000000000000000000000000000", to: URL.self)
            XCTAssertEqual(decoded.absoluteString, "https://www.cryptoatoms.org/cres/uri/330")
        } catch let error {
            print(error.localizedDescription)
            XCTFail()
        }
    }
    
    func test_GivenDynamicArrayOfAddresses_ThenDecodesCorrectly() {
        do {
            let addresses = ["0x26fc876db425b44bf6c377a7beef65e9ebad0ec3",
                             "0x25a01a05c188dacbcf1d61af55d4a5b4021f7eed",
                             "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
                             "0x8c2dc702371d73febc50c6e6ced100bf9dbcb029",
                             "0x007eedb5044ed5512ed7b9f8b42fe3113452491e"].map { EthereumAddress($0) }
            
            let value = try ABIDecoder.decodeData("0x0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000500000000000000000000000026fc876db425b44bf6c377a7beef65e9ebad0ec300000000000000000000000025a01a05c188dacbcf1d61af55d4a5b4021f7eed000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0000000000000000000000008c2dc702371d73febc50c6e6ced100bf9dbcb029000000000000000000000000007eedb5044ed5512ed7b9f8b42fe3113452491e", types: [[EthereumAddress].self])
            XCTAssertEqual(try value[0].decoded(), addresses)
        } catch let error {
            print(error.localizedDescription)
            XCTFail()
        }
    }
}


