//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation
@testable import web3_zksync
@testable import web3
import XCTest
import BigInt


final class EthereumClientZKSyncTests: XCTestCase {
    let eoaAccount = try! EthereumAccount(keyStorage: TestEthereumKeyStorage(privateKey: TestConfig.privateKey))
    let client = ZKSyncClient(url: TestConfig.ZKSync.clientURL, network: TestConfig.ZKSync.network)
    var eoaEthTransfer = ZKSyncTransaction(
        from: .init(TestConfig.publicKey),
        to: .init("0x64d0eA4FC60f27E74f1a70Aa6f39D403bBe56793"),
        value: 100,
        data: Data(),
        gasLimit: 300000
    )
    
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
