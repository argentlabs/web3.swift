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
    let client = EthereumClient(url: TestConfig.ZKSync.clientURL)
    let eoaEthTransfer = ZKSyncTransaction(
        to: .init("0x64d0eA4FC60f27E74f1a70Aa6f39D403bBe56793"),
        value: BigUInt(hex: "0xe8d4a51000")!,
        data: Data(),
        gasPrice: 20,
        gasLimit: 50000
    )
    
    func test_GivenEOAAccount_WhenSendETH_ThenSendsCorrectly() async {
        do {
            let txHash = try await client.eth_sendRawZKSyncTransaction(eoaEthTransfer, withAccount: eoaAccount)
            XCTAssertNotNil(txHash, "No tx hash, ensure key is valid in TestConfig.swift")
        } catch {
            XCTFail("Expected tx but failed \(error).")
        }
    }
    
    func test_GivenEOAAccount_WhenSendETH_AndFeeIsInUSDC_ThenSendsCorrectly() async {
        do {
            let txHash = try await client.eth_sendRawZKSyncTransaction(with(eoaEthTransfer) {
                $0.feeToken = EthereumAddress("0x54a14D7559BAF2C8e8Fa504E019d32479739018c")
            }, withAccount: eoaAccount)
            XCTAssertNotNil(txHash, "No tx hash, ensure key is valid in TestConfig.swift")
        } catch {
            XCTFail("Expected tx but failed \(error).")
        }
    }
    
    let aaAccount = try! EthereumAccount(keyStorage: TestEthereumKeyStorage(privateKey: "0x1602a4f9e985b092ec0950b52c64bbea2158c1917851c10ae28e405fca267610"))
    let aaEthTransfer = ZKSyncTransaction(
        to: .init("0x64d0eA4FC60f27E74f1a70Aa6f39D403bBe56793"),
        value: BigUInt(hex: "0xe8d4a51000")!,
        data: Data(),
        gasPrice: 20,
        gasLimit: 50000,
        egsPerPubdata: 0,
        feeToken: .zero,
        aaParams: .init(
            from: EthereumAddress("0x143b06e4963e5A1dc056a8a41C11746a504d46Cc")
        )
    )
    
    func test_GivenAAAccount_WhenSendETH_ThenSendsCorrectly() async {
        do {
            let txHash = try await client.eth_sendRawZKSyncTransaction(aaEthTransfer, withAccount: aaAccount)
            XCTAssertNotNil(txHash, "No tx hash, ensure key is valid in TestConfig.swift")
        } catch {
            XCTFail("Expected tx but failed \(error).")
        }
    }
    
    func test_GivenAAAccount_WhenSendETH_AndFeeIsUSDC_ThenSendsCorrectly() async {
        do {
            let txHash = try await client.eth_sendRawZKSyncTransaction(
                with(aaEthTransfer) {
                    $0.feeToken = EthereumAddress("0x54a14D7559BAF2C8e8Fa504E019d32479739018c")
                }, withAccount: aaAccount)
            XCTAssertNotNil(txHash, "No tx hash, ensure key is valid in TestConfig.swift")
        } catch {
            XCTFail("Expected tx but failed \(error).")
        }
    }
}
