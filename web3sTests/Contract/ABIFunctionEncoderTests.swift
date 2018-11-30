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
}
