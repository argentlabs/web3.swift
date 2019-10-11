//
//  ABIFunctionTests.swift
//  web3swift
//
//  Created by Miguel on 10/10/2019.
//  Copyright © 2019 Argent Labs Limited. All rights reserved.
//

import XCTest
import BigInt
@testable import web3swift

struct Deposit_NoParameter: ABIFunction {
    static let name = "deposit"
    let gasPrice: BigUInt? = nil
    let gasLimit: BigUInt? = nil
    var contract = EthereumAddress("0xFFB9239F43673068E3c8D7664382Dd6Fdd6e40cb")
    let from: EthereumAddress? = nil
    
    
    func encode(to encoder: ABIFunctionEncoder) throws {
    }
}

struct BalanceOf_Parameter: ABIFunction {
    static let name = "balanceOf"
    let gasPrice: BigUInt? = nil
    let gasLimit: BigUInt? = nil
    var contract = EthereumAddress("0xFFB9239F43673068E3c8D7664382Dd6Fdd6e40cb")
    let account: EthereumAddress
    let from: EthereumAddress? = nil
    
    func encode(to encoder: ABIFunctionEncoder) throws {
        try encoder.encode(account)
    }
}

class ABIFunctionTests: XCTestCase {
    let noparam = Deposit_NoParameter()
    let oneParam = BalanceOf_Parameter(account: .zero)

    func test_GivenRawTxCallData_WhenPassingNoParams_ThenDecodesNoParamTransaction() {
        let data = Data(hex: "0xd0e30db0")!
        let decoded = try? noparam.decode(data, expectedTypes: [])
        XCTAssertEqual(decoded?.count, 0)
    }
    
    func test_GivenRawTxCallData_WhenPassingAnyParam_ThenFailsDecodingNoParamTransaction() {
        let data = Data(hex: "0xd0e30db0")!
        let decoded = try? noparam.decode(data, expectedTypes: [String.self])
        XCTAssertNil(decoded)
    }
    
    func test_GivenRawTxCallData_WhenPassingParam_ThenDecodesParamTransaction() {
        let data = Data(hex: "0x70a08231000000000000000000000000655ef694b98e55977a93259cb3b708560869a8f3")!
        let decoded = try? oneParam.decode(data, expectedTypes: [EthereumAddress.self])
        XCTAssertEqual((decoded?[0] as? EthereumAddress), EthereumAddress("0x655ef694b98e55977a93259cb3b708560869a8f3"))
    }
    
    func test_GivenRawTxCallData_WhenPassingWrongParam_ThenFailsDecodingOneParamTransaction() {
        let data = Data(hex: "0x70a08231000000000000000000000000655ef694b98e55977a93259cb3b708560869a8f3")!
        let decoded = try? oneParam.decode(data, expectedTypes: [Bool.self])
        XCTAssertNil(decoded)
    }
}

