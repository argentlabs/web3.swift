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

class ABIFuncionEncoderTests: XCTestCase {
    var encoder: ABIFunctionEncoder!
    
    override func setUp() {
        encoder = ABIFunctionEncoder("test")

    }
    
    func testGivenEmptyString_ThenEncodesCorrectly() {
        try! encoder.encode("")
        let encoded = try! encoder.encoded()
        XCTAssertEqual(String(hexFromBytes: encoded.bytes), "0xf9fbd554000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000")
    }
    
    func testGivenNonEmptyString_ThenEncodesCorrectly() {
        try! encoder.encode("hi")
        let encoded = try! encoder.encoded()
        XCTAssertEqual(String(hexFromBytes: encoded.bytes), "0xf9fbd554000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000026869000000000000000000000000000000000000000000000000000000000000")
    }

    func testGivenEmptyData_ThenEncodesCorrectly() {
        try! encoder.encode(Data())
        let encoded = try! encoder.encoded()
        XCTAssertEqual(String(hexFromBytes: encoded.bytes), "0x2f570a2300000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000")
    }
    
    func testGivenNonEmptyData_ThenEncodesCorrectly() {
        try! encoder.encode(Data(bytes: "hi".bytes))
        let encoded = try! encoder.encoded()
        XCTAssertEqual(String(hexFromBytes: encoded.bytes), "0x2f570a23000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000026869000000000000000000000000000000000000000000000000000000000000")
    }
    
    func testGivenEmptyArrayOfAddressses_ThenEncodesCorrectly() {
        try! encoder.encode([EthereumAddress]())
        let encoded = try! encoder.encoded()
        XCTAssertEqual(String(hexFromBytes: encoded.bytes), "0xd57498ea00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000")
    }
    
    
    func testGivenArrayOfAddressses_ThenEncodesCorrectly() {
        let addresses = ["0x26fc876db425b44bf6c377a7beef65e9ebad0ec3",
                         "0x25a01a05c188dacbcf1d61af55d4a5b4021f7eed",
                         "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
                         "0x8c2dc702371d73febc50c6e6ced100bf9dbcb029",
                         "0x007eedb5044ed5512ed7b9f8b42fe3113452491e"].map { EthereumAddress($0) }

        try! encoder.encode(addresses)
        let encoded = try! encoder.encoded()
        XCTAssertEqual(String(hexFromBytes: encoded.bytes), "0xd57498ea0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000026fc876db425b44bf6c377a7beef65e9ebad0ec300000000000000000000000025a01a05c188dacbcf1d61af55d4a5b4021f7eed000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0000000000000000000000008c2dc702371d73febc50c6e6ced100bf9dbcb029000000000000000000000000007eedb5044ed5512ed7b9f8b42fe3113452491e0000000000000000000000000000000000000000000000000000000000000000")
    }
}
