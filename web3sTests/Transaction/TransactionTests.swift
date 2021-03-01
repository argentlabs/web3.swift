//
//  TransactionTests.swift
//  web3swift
//
//  Created by Miguel on 11/07/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import XCTest
import BigInt
@testable import web3

class TransactionTests: XCTestCase {
    let withoutChainID: EthereumTransaction = EthereumTransaction(from: EthereumAddress("0x2639f727ded571d584643895d43d02a7a190f8249748a2c32200cfc12dde7173"),
                                                                  to: EthereumAddress("0x1639f727ded571d584643895d43d02a7a190f8249748a2c32200cfc12dde7174"),
                                                                  value: 0,
                                                                  data: Data(),
                                                                  nonce: 1,
                                                                  gasPrice: 10,
                                                                  gasLimit: 400000,
                                                                  chainId: nil)
    
    func test_GivenLocalTransaction_WhenTransactionOnlyWithToAndData_HashIsNil() {
        let transaction = EthereumTransaction(to: EthereumAddress("0x2639f727ded571d584643895d43d02a7a190f8249748a2c32200cfc12dde7173"),
                                              data: Data())
        XCTAssertNil(transaction.hash)
    }
    
    func test_GivenLocalTransaction_WhenTransactionDoesNotHaveNonce_HashIsNil() {
        let transaction = EthereumTransaction(from: EthereumAddress("0x2639f727ded571d584643895d43d02a7a190f8249748a2c32200cfc12dde7173"),
                                              to: EthereumAddress("0x1639f727ded571d584643895d43d02a7a190f8249748a2c32200cfc12dde7174"),
                                              data: Data(),
                                              gasPrice: 10,
                                              gasLimit: 400000)
        XCTAssertNil(transaction.hash)
    }
    
    func test_GivenLocalTransaction_WhenTransactionWithNonce_HashIsCorrect() {
        let transaction = EthereumTransaction(from: EthereumAddress("0x2639f727ded571d584643895d43d02a7a190f8249748a2c32200cfc12dde7173"),
                                              to: EthereumAddress("0x1639f727ded571d584643895d43d02a7a190f8249748a2c32200cfc12dde7174"),
                                              value: 0,
                                              data: Data(),
                                              nonce: 1,
                                              gasPrice: 10,
                                              gasLimit: 400000,
                                              chainId: 3)

        XCTAssertEqual(transaction.hash?.web3.hexString, "0xec010a83061a80a01639f727ded571d584643895d43d02a7a190f8249748a2c32200cfc12dde71748080038080")
    }
    
    func test_GivenLocalTransaction_WhenTransactionWithoutChainID_HashIsNil() {
        XCTAssertNil(withoutChainID.hash)
    }
    
    func test_GivenTransactionWithoutChainID_WhenChainIDIsSet_HashIsCorrect() {
        var withChainId = withoutChainID
        withChainId.chainId = 3
        XCTAssertEqual(withChainId.hash?.web3.hexString, "0x91f25d392d2b9cb70acdd14bcaa08b596b16661e26fbf2fa8a05f68edf19fcea")
    }
}

