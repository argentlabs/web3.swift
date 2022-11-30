//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation
@testable import web3
import XCTest
import BigInt


final class EthereumClientZKSyncTests: XCTestCase {
    let eoaAccount = try! EthereumAccount(keyStorage: TestEthereumKeyStorage(privateKey: TestConfig.privateKey))
    let client = ZKSyncClient(url: TestConfig.ZKSync.clientURL)
    var eoaEthTransfer = ZKSyncTransaction(
        from: .init("0x719561fee351F7aC6560D0302aE415FfBEEc0B51"),
        to: .init("0x64d0eA4FC60f27E74f1a70Aa6f39D403bBe56793"),
        value: BigUInt(hex: "0xe8d4a51000")!,
        data: Data(),
        gasLimit: 5000000
    )
    
    func test_GivenEOAAccount_WhenSendETH_ThenSendsCorrectly() async {
        do {
            let gasPrice = try await client.eth_gasPrice()
            eoaEthTransfer.gasPrice = gasPrice
            let txHash = try await client.eth_sendRawZKSyncTransaction(eoaEthTransfer, withAccount: eoaAccount)
            XCTAssertNotNil(txHash, "No tx hash, ensure key is valid in TestConfig.swift")
        } catch {
            XCTFail("Expected tx but failed \(error).")
        }
    }
    
    // TODO: Integrate paymaster
//    func test_GivenEOAAccount_WhenSendETH_AndFeeIsInUSDC_ThenSendsCorrectly() async {
//        do {
//            let txHash = try await client.eth_sendRawZKSyncTransaction(with(eoaEthTransfer) {
//                $0.feeToken = EthereumAddress("0x54a14D7559BAF2C8e8Fa504E019d32479739018c")
//            }, withAccount: eoaAccount)
//            XCTAssertNotNil(txHash, "No tx hash, ensure key is valid in TestConfig.swift")
//        } catch {
//            XCTFail("Expected tx but failed \(error).")
//        }
//    }
    
    func test_GivenEOATransaction_gasEstimationCorrect() async {
        do {
            let estimate = try await client.estimateGas(
                with(eoaEthTransfer) {
                    $0.gasPrice = nil
                    $0.gasLimit = nil
                }
            )
            XCTAssertGreaterThan(estimate, 1000)
        } catch {
            XCTFail("Expected value but failed \(error).")
        }
    }
}
