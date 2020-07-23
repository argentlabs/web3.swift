//
//  ABIFunctionEncoderTests.swift
//  web3swift
//
//  Created by Miguel on 28/11/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import XCTest
import BigInt
@testable import web3swift

class ABIFunctionEncoderTests: XCTestCase {
    var encoder: ABIFunctionEncoder!
    
    override func setUp() {
        encoder = ABIFunctionEncoder("test")

    }
    
    func testGivenEmptyString_ThenEncodesCorrectly() {
        try! encoder.encode("")
        let encoded = try! encoder.encoded()
        XCTAssertEqual(String(hexFromBytes: encoded.web3.bytes), "0xf9fbd554000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000")
    }
    
    func testGivenNonEmptyString_ThenEncodesCorrectly() {
        try! encoder.encode("hi")
        let encoded = try! encoder.encoded()
        XCTAssertEqual(String(hexFromBytes: encoded.web3.bytes), "0xf9fbd554000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000026869000000000000000000000000000000000000000000000000000000000000")
    }

    func testGivenEmptyData_ThenEncodesCorrectly() {
        try! encoder.encode(Data())
        let encoded = try! encoder.encoded()
        XCTAssertEqual(String(hexFromBytes: encoded.web3.bytes), "0x2f570a2300000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000")
    }
    
    func testGivenNonEmptyData_ThenEncodesCorrectly() {
        try! encoder.encode(Data("hi".web3.bytes))
        let encoded = try! encoder.encoded()
        XCTAssertEqual(String(hexFromBytes: encoded.web3.bytes), "0x2f570a23000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000026869000000000000000000000000000000000000000000000000000000000000")
    }
    
    func testGivenStaticSizeData4_ThenEncodesCorrectly() {
        try! encoder.encode(Data(hex: "0xffffffff")!, staticSize: 4)
        let encoded = try! encoder.encoded()
        XCTAssertEqual(String(hexFromBytes: encoded.web3.bytes), "0xda67eb8affffffff00000000000000000000000000000000000000000000000000000000")
    }
    
    func testGivenEmptyArrayOfAddressses_ThenEncodesCorrectly() {
        try! encoder.encode([EthereumAddress]())
        let encoded = try! encoder.encoded()
        XCTAssertEqual(String(hexFromBytes: encoded.web3.bytes), "0xd57498ea00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000")
    }
    
    
    func testGivenArrayOfAddressses_ThenEncodesCorrectly() {
        let addresses = ["0x26fc876db425b44bf6c377a7beef65e9ebad0ec3",
                         "0x25a01a05c188dacbcf1d61af55d4a5b4021f7eed",
                         "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
                         "0x8c2dc702371d73febc50c6e6ced100bf9dbcb029",
                         "0x007eedb5044ed5512ed7b9f8b42fe3113452491e"].map(EthereumAddress.init)

        try! encoder.encode(addresses)
        let encoded = try! encoder.encoded()
        XCTAssertEqual(String(hexFromBytes: encoded.web3.bytes), "0xd57498ea0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000500000000000000000000000026fc876db425b44bf6c377a7beef65e9ebad0ec300000000000000000000000025a01a05c188dacbcf1d61af55d4a5b4021f7eed000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0000000000000000000000008c2dc702371d73febc50c6e6ced100bf9dbcb029000000000000000000000000007eedb5044ed5512ed7b9f8b42fe3113452491e")
    }
    
    func testGivenMultiBytes_ThenEncodesCorrectly() {
        let sigData = Data(hex: "0x450298c35b4713c9722b9b771f67d004ece1d25cbd33534e5932ea88172d23e90600203208a3ef63195f75702b61da1715aa785784c75f7a92958800095081221c")!
        let wallet = EthereumAddress("0xfbbcfe69b3941682d87d6bec0b64099e00d78f8e")
        let data = Data(hex: "0x2df546f4000000000000000000000000fbbcfe69b3941682d87d6bec0b64099e00d78f8e000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000a78a7b5926c52c10f4b7e84d085f1999c5ec89ff000000000000000000000000000000000000000000000000016345785d8a000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000000")!
        
        let exec = RelayerExecute(from: nil, gasPrice: nil, gasLimit: nil, wallet: wallet, data: data, nonce: .zero, signatures: sigData, _gasPrice: .zero, _gasLimit: .zero)
        
        let execData = try! exec.transaction().data!
        XCTAssertEqual(execData.web3.hexString, "0xaacaaf88000000000000000000000000fbbcfe69b3941682d87d6bec0b64099e00d78f8e00000000000000000000000000000000000000000000000000000000000000c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c42df546f4000000000000000000000000fbbcfe69b3941682d87d6bec0b64099e00d78f8e000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000a78a7b5926c52c10f4b7e84d085f1999c5ec89ff000000000000000000000000000000000000000000000000016345785d8a000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000041450298c35b4713c9722b9b771f67d004ece1d25cbd33534e5932ea88172d23e90600203208a3ef63195f75702b61da1715aa785784c75f7a92958800095081221c00000000000000000000000000000000000000000000000000000000000000")
    }
    
    func testGivenArrayOfBigUInt_ThenEncodesCorrectly() {
        let values = [BigUInt(1),BigUInt(2),BigUInt(3)]

        try! encoder.encode(values)
        let encoded = try! encoder.encoded()
        XCTAssertEqual(String(hexFromBytes: encoded.web3.bytes), "0xca16068400000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000003")
    }
    
    func testGivenArrayOfStrings_ThenEncodesCorrectly() {
        let values = ["abc"]
        
        do {
            try encoder.encode(values)
            XCTAssertEqual(try encoder.encoded().web3.hexString, "0xe21b90eb00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000036162630000000000000000000000000000000000000000000000000000000000")
        } catch {
            XCTFail()
        }
    }
    
    func testGivenSimpleTuple_ThenEncodesCorrectly() {
        let tuple = SimpleTuple(address: EthereumAddress("0x64d0ea4fc60f27e74f1a70aa6f39d403bbe56793"), amount: BigUInt(30))
        
        do {
            try encoder.encode(tuple)
            XCTAssertEqual(try encoder.encoded().web3.hexString,"0xba71720c00000000000000000000000064d0ea4fc60f27e74f1a70aa6f39d403bbe56793000000000000000000000000000000000000000000000000000000000000001e")
        } catch let error {
            print(error.localizedDescription)
            XCTFail()
        }
    }
    
    func testGivenDynamicContentTuple_ThenEncodesCorrectly() {
        let tuple = DynamicContentTuple(message: "abc")
        
        do {
            try encoder.encode(tuple)
            XCTAssertEqual(try encoder.encoded().web3.hexString,"0xd6c9f12a0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000036162630000000000000000000000000000000000000000000000000000000000")
        } catch let error {
            print(error.localizedDescription)
            XCTFail()
        }
    }
    
    func testGivenTupleAndArgument_ThenEncodesCorrectly() {
        let tuple = DynamicContentTuple(message: "abc")
        
        do {
            try encoder.encode(tuple)
            try encoder.encode(BigUInt(1))
            XCTAssertEqual(try encoder.encoded().web3.hexString,
            "0x969569a200000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000036162630000000000000000000000000000000000000000000000000000000000")
        } catch let error {
            print(error.localizedDescription)
            XCTFail()
        }
    }
    
    func testGivenArrayOfTuples_ThenEncodesCorrectly() {
        let tuples = [
            SimpleTuple(address: EthereumAddress("0x64d0eA4FC60f27E74f1a70Aa6f39D403bBe56793"), amount: 30),
            SimpleTuple(address: EthereumAddress("0x3C1Bd6B420448Cf16A389C8b0115CCB3660bB854"), amount: 120)]
        
        do {
            try encoder.encode(tuples)
            XCTAssertEqual(try encoder.encoded().web3.hexString,
            "0xae4f5efa0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000200000000000000000000000064d0ea4fc60f27e74f1a70aa6f39d403bbe56793000000000000000000000000000000000000000000000000000000000000001e0000000000000000000000003c1bd6b420448cf16a389c8b0115ccb3660bb8540000000000000000000000000000000000000000000000000000000000000078")
        } catch let error {
            print(error.localizedDescription)
            XCTFail()
        }
    }
}

fileprivate struct SimpleTuple: ABITuple {
    static var types: [ABIType.Type] { [EthereumAddress.self, BigUInt.self] }
    
    var address: EthereumAddress
    var amount: BigUInt
    
    init(address: EthereumAddress,
         amount: BigUInt) {
        self.address = address
        self.amount = amount
    }
    
    init?(values: [ABIType]) throws {
        self.address = try values[0].decoded()
        self.amount = try values[1].decoded()
    }
    
    var encodableValues: [ABIType] { [address, amount] }
}

fileprivate struct DynamicContentTuple: ABITuple {
    static var types: [ABIType.Type] { [String.self] }
    
    var message: String
    
    init(message: String) {
        self.message = message
    }
    
    init?(values: [ABIType]) throws {
        self.message = try values[0].decoded()
    }
    
    var encodableValues: [ABIType] { [message] }
}

fileprivate struct RelayerExecute: ABIFunction {
    static let name = "execute"
    let contract = EthereumAddress.zero
    let from: EthereumAddress?
    var gasPrice: BigUInt?
    var gasLimit: BigUInt?

    struct Response: ABIResponse {
        static var types: [ABIType.Type] = []

        init?(values: [ABIType]) throws {

        }
    }

    let wallet: EthereumAddress
    let data: Data
    let nonce: BigUInt
    let signatures: Data
    let _gasPrice: BigUInt
    let _gasLimit: BigUInt
    
    func encode(to encoder: ABIFunctionEncoder) throws {
        try encoder.encode(wallet)
        try encoder.encode(data)
        try encoder.encode(nonce)
        try encoder.encode(signatures)
        try encoder.encode(_gasPrice)
        try encoder.encode(_gasLimit)
    }
}

