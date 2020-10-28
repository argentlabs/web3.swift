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
    func testDecodeUint32() {
        do {
            let decoded = try ABIDecoder.decodeData("0x000000000000000000000000000000000000000000000000000000000000002a", types: [BigInt.self])
            XCTAssertEqual(try decoded[0].decoded(), BigInt(42))
        } catch let error {
            print(error.localizedDescription)
            XCTFail()
        }
    }
    
    func testDecodeUint256Array() {
        do {
            let decoded = try ABIDecoder.decodeData("0x00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000003", types: [ABIArray<BigInt>.self])
            XCTAssertEqual(try decoded[0].decodedArray(), [BigInt(1), BigInt(2), BigInt(3)])
        } catch let error {
            print(error.localizedDescription)
            XCTFail()
        }
    }
    
    func testDecodeAddress() {
        do {
            let decoded = try ABIDecoder.decodeData("0x00000000000000000000000021397c1a1f4acd9132fe36df011610564b87e24b", types: [EthereumAddress.self])
            XCTAssertEqual(try decoded[0].decoded(), EthereumAddress("0x21397c1a1f4acd9132fe36df011610564b87e24b"))
        } catch let error {
            print(error.localizedDescription)
            XCTFail()
        }
        
    }
    
    func testDecodeString() {
        do {
            let decoded = try ABIDecoder.decodeData("0x000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000147665726f6e696b612e617267656e742e74657374000000000000000000000000", types: [String.self])
            let result: String = try decoded[0].decoded()
            XCTAssertEqual(result.web3.stringValue, "veronika.argent.test")
        } catch let error {
            print(error.localizedDescription)
            XCTFail()
        }
        
    }
    
    func testDecodeAddressArray() {
        do {
            let decoded = try ABIDecoder.decodeData("0x000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a77b0f3aae325cb2ec1bdb4a3548d816a83b8ca3", types: [ABIArray<EthereumAddress>.self])
            XCTAssertEqual(try decoded[0].decodedArray(), [.zero, EthereumAddress("0xa77b0f3aae325cb2ec1bdb4a3548d816a83b8ca3")])
        } catch let error {
            print(error.localizedDescription)
            XCTFail()
        }
        
    }
    
    func testDecodeFixedBytes1() {
        do {
            let decoded = try ABIDecoder.decodeData("0x63000000000000000000000000000000000000000000000000000000000000", types: [Data1.self])
            XCTAssertEqual(try decoded[0].decoded(), Data(hex: "0x63")!)
        } catch let error {
            print(error.localizedDescription)
            XCTFail()
        }
    }
    
    func testDecodeFixedBytes3() {
        do {
            let decoded = try ABIDecoder.decodeData("0x6162630000000000000000000000000000000000000000000000000000000000", types: [Data3.self])
            XCTAssertEqual(try decoded[0].decoded(), Data(hex: "0x616263")!)
        } catch let error {
            print(error.localizedDescription)
            XCTFail()
        }
    }
    
    func testDecodeFixedBytes32() {
        do {
            let decoded = try ABIDecoder.decodeData("0x0200000000000000000000000050000000000000000000000000000000616263", types: [Data32.self])
            XCTAssertEqual(try decoded[0].decoded(), Data(hex: "0x0200000000000000000000000050000000000000000000000000000000616263")!)
        } catch let error {
            print(error.localizedDescription)
            XCTFail()
        }
    }
    
    func testDecodeEmptyDynamicData() {
        do {
            let decoded = try ABIDecoder.decodeData("0x00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000", types: [Data.self])
            XCTAssertEqual(try decoded[0].decoded(), Data())
        } catch let error {
            print(error.localizedDescription)
            XCTFail()
        }
    }
    
    func testDecodeDynamicData() {
        do {
            let decoded = try ABIDecoder.decodeData("0x0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000d48656c6c6f2c20776f726c642100000000000000000000000000000000000000", types: [Data.self])
                
            XCTAssertEqual(try decoded[0].decoded(), Data(hex: "0x48656c6c6f2c20776f726c6421")!)
        } catch let error {
            print(error.localizedDescription)
            XCTFail()
        }
    }

    func testDecodeBytesArray() {
        do {
            let decoded = try ABIDecoder.decodeData(
                "0x0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000018000000000000000000000000000000000000000000000000000000000000001c000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000001753796e746865746978204e6574776f726b20546f6b656e000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000003534e5800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000012"
                , types: [ABIArray<String>.self], asArray: false)

            XCTAssertEqual(try ERC20Responses.nameResponse(data: decoded[0].entry[0])?.value, "Synthetix Network Token")
            XCTAssertEqual(try ERC20Responses.symbolResponse(data: decoded[0].entry[1])?.value, "SNX")
            XCTAssertEqual(try ERC20Responses.balanceResponse(data: decoded[0].entry[2])?.value, BigUInt(integerLiteral: 0))
            XCTAssertEqual(try ERC20Responses.decimalsResponse(data: decoded[0].entry[3])?.value, 18)
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
            
            let result = try ABIDecoder.decodeData("0x0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000500000000000000000000000026fc876db425b44bf6c377a7beef65e9ebad0ec300000000000000000000000025a01a05c188dacbcf1d61af55d4a5b4021f7eed000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0000000000000000000000008c2dc702371d73febc50c6e6ced100bf9dbcb029000000000000000000000000007eedb5044ed5512ed7b9f8b42fe3113452491e", types: [ABIArray<EthereumAddress>.self])
            XCTAssertEqual(try result[0].decodedArray(), addresses)
        } catch let error {
            print(error.localizedDescription)
            XCTFail()
        }
    }
    
    func test_GivenDynamicArrayOfUint_ThenDecodesCorrectly() {
        do {
            let values = [BigUInt(1),BigUInt(2),BigUInt(3)]
            
            let result = try ABIDecoder.decodeData("0x00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000003", types: [ABIArray<BigUInt>.self])
            XCTAssertEqual(try result[0].decodedArray(), values)
        } catch let error {
            print(error.localizedDescription)
            XCTFail()
        }
    }
    
    func test_GivenExpectingBigInt_WhenEmptyDataMarker_ThenDecodeSucceeds() {
        do {
            let value = try ABIDecoder.decodeData("0x", types: [BigInt.self])
            XCTAssertEqual(try value[0].decoded(), BigInt(0))
        } catch let error {
            print(error.localizedDescription)
            XCTFail()
        }
    }
    
    func test_GivenExpectingBigUInt_WhenEmptyDataMarker_ThenDecodeSucceeds() {
        do {
            let value = try ABIDecoder.decodeData("0x", types: [BigUInt.self])
            XCTAssertEqual(try value[0].decoded(), BigUInt(0))
        } catch let error {
            print(error.localizedDescription)
            XCTFail()
        }
    }
    
    func test_GivenExpectingUInt_WhenEmptyDataMarker_ThenDecodeSuceeds() {
        do {
            let value = try ABIDecoder.decodeData("0x", types: [UInt64.self])
            XCTAssertEqual(try value[0].decoded(), UInt64(0))
        } catch let error {
            print(error.localizedDescription)
            XCTFail()
        }
    }
    
    func test_GivenExpectingAddress_WhenEmptyDataMarker_ThenDecodeFails() {
        do {
            let _ = try ABIDecoder.decodeData("0x", types: [EthereumAddress.self])
            XCTFail()
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func test_GivenExpectingBool_WhenEmptyDataMarker_ThenDecodeFails() {
        do {
            let _ = try ABIDecoder.decodeData("0x", types: [Bool.self])
            XCTFail()
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func test_GivenExpectingData_WhenEmptyDataMarker_ThenDecodeSucceeds() {
        do {
            let data = try ABIDecoder.decodeData("0x", types: [Data.self])
            XCTAssertEqual(try data[0].decoded(), Data())
        } catch let error {
            print(error.localizedDescription)
            XCTFail()
        }
    }
    
    func test_GivenExpectingString_WhenEmptyDataMarker_ThenDecodeSucceeds() {
        do {
            let data = try ABIDecoder.decodeData("0x", types: [String.self])
            XCTAssertEqual(try data[0].decoded(), "")
        } catch let error {
            print(error.localizedDescription)
            XCTFail()
        }
    }
    
    func test_GivenExpectingManyElements_WhenEmptyDataMarker_ThenDecodeFails() {
        do {
            let _ = try ABIDecoder.decodeData("0x", types: [String.self, String.self])
            XCTFail()
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func test_GivenExpectingArrayOfElements_WhenEmptyDataMarker_ThenDecodeFails() {
        do {
            let _ = try ABIDecoder.decodeData("0x", types: [String.self], asArray: true)
            XCTFail()
        } catch let error {
            print(error.localizedDescription)
        }
    }
}

