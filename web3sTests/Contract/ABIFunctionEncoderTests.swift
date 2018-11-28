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

    func testGivenEmptyData_ThenEncodesCorrectly() {
        try! encoder.encode(Data())
        let encoded = try! encoder.encoded()
        XCTAssertEqual(String(hexFromBytes: encoded.bytes), "0x2f570a23000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000")
    }
    
    func testGivenNonEmptyData_ThenEncodesCorrectly() {
        print("hi".bytes)
        try! encoder.encode(Data(bytes: "hi".bytes))
        let encoded = try! encoder.encoded()
        XCTAssertEqual(String(hexFromBytes: encoded.bytes), "0x2f570a23000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000026869000000000000000000000000000000000000000000000000000000000000")
    }
}
