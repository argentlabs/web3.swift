//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import XCTest
@testable import web3
import BigInt

final class ZKSyncTransactionTests: XCTestCase {
    
    let eoaAccount = try! EthereumAccount(keyStorage: TestEthereumKeyStorage(privateKey: "0xf707ce8805f09a68294b4efdfad686629b31a5128670ef0e502c8c396181f1cb"))
    let aaAccount = try! EthereumAccount(keyStorage: TestEthereumKeyStorage(privateKey: "0x2639f727ded571d584643895d43d02a7a190f8249748a2c32200cfc12dde7173"))
    
    let eoaTransfer = ZKSyncTransaction(
        to: .init("0x64d0eA4FC60f27E74f1a70Aa6f39D403bBe56793"),
        value: BigUInt(hex: "0xe8d4a51000")!,
        data: Data(),
        chainId: TestConfig.ZKSync.chainId,
        nonce: 3,
        gasPrice: BigUInt(hex: "0x6f9c")!,
        gasLimit: BigUInt(hex: "0x55af")!,
        egsPerPubdata: 0,
        feeToken: .zero
    )
    
    func test_GivenEOATransfer_EncodesCorrectly() {
        let signature = "0xbb1e86080318c07c16ccc857b2b4bcdff1b0be0bc72e4483e099f65f0d2260f420069efe1eb9436ffc21ea7787f0bb8a5484b7529d33e84471c8882754c0c6321b".web3.hexData!
        let signed = ZKSyncSignedTransaction(
            transaction: eoaTransfer, sigParam: .eoa(.init(raw: signature))
        )
        XCTAssertEqual(signed.raw?.web3.hexString, "0x71f88103826f9c8255af9464d0ea4fc60f27e74f1a70aa6f39d403bbe5679385e8d4a510008080a0bb1e86080318c07c16ccc857b2b4bcdff1b0be0bc72e4483e099f65f0d2260f4a020069efe1eb9436ffc21ea7787f0bb8a5484b7529d33e84471c8882754c0c63282011894000000000000000000000000000000000000000080c0c0")
    }
    
    func test_GivenEOATransfer_WhenFeeTokenIsNotZeroEncodesCorrectly() {
        let signature = "0x9ed74a3db2a5632ac645af62e0e4ebb9f1ee8998143246449f1c26a5e50a1d4f2ed4e3f8b395f31ab70f90aa464a6d1f86a2a11521de44c74953ba1a910bd4c91c".web3.hexData!
        let signed = ZKSyncSignedTransaction(
            transaction: with( eoaTransfer) { $0.feeToken = EthereumAddress("0x54a14D7559BAF2C8e8Fa504E019d32479739018c")
            }, sigParam: .eoa(.init(raw: signature))
        )
        
        XCTAssertEqual(signed.raw?.web3.hexString, "0x71f88103826f9c8255af9464d0ea4fc60f27e74f1a70aa6f39d403bbe5679385e8d4a510008001a09ed74a3db2a5632ac645af62e0e4ebb9f1ee8998143246449f1c26a5e50a1d4fa02ed4e3f8b395f31ab70f90aa464a6d1f86a2a11521de44c74953ba1a910bd4c98201189454a14d7559baf2c8e8fa504e019d32479739018c80c0c0")
    }
    
    func test_GivenEOATransfer_WhenSigningWithEOAAccount_ThenSignsAndEncodesCorrectly()  {
        let signed = try? eoaAccount.sign(zkTransaction: eoaTransfer)
        
        XCTAssertEqual(signed?.raw?.web3.hexString,
                       "0x71f88103826f9c8255af9464d0ea4fc60f27e74f1a70aa6f39d403bbe5679385e8d4a510008080a0bb1e86080318c07c16ccc857b2b4bcdff1b0be0bc72e4483e099f65f0d2260f4a020069efe1eb9436ffc21ea7787f0bb8a5484b7529d33e84471c8882754c0c63282011894000000000000000000000000000000000000000080c0c0")
    }
    
    let aaTransfer = ZKSyncTransaction(
        to: .init("0x64d0eA4FC60f27E74f1a70Aa6f39D403bBe56793"),
        value: BigUInt(hex: "0xe8d4a51000")!,
        data: Data(),
        chainId: TestConfig.ZKSync.chainId,
        nonce: 30,
        gasPrice: BigUInt(hex: "0x6f9c")!,
        gasLimit: BigUInt(hex: "0x55af")!,
        egsPerPubdata: 0,
        feeToken: .zero,
        aaParams: .init(
            from: EthereumAddress("0x143b06e4963e5A1dc056a8a41C11746a504d46Cc")
        )
    )

    func test_GivenAATransfer_EncodesCorrectly() {
        let signature = "0x8525c1f93285a15ade22ef2626b97fa4d315c56d894210781b287118dfd053954a4bb9ef7cbf329d5c8e19e580636ffe4db97d74aa0d53215f823aa5d63500b31c".web3.hexData!
        let signed = ZKSyncSignedTransaction(
            transaction: aaTransfer, sigParam: .aa(signature: .init(raw: signature), from: EthereumAddress("0x143b06e4963e5A1dc056a8a41C11746a504d46Cc"))
        )
        XCTAssertEqual(signed.raw?.web3.hexString, "0x71f89c1e826f9c8255af9464d0ea4fc60f27e74f1a70aa6f39d403bbe5679385e8d4a5100080820118808082011894000000000000000000000000000000000000000080c0f85894143b06e4963e5a1dc056a8a41c11746a504d46ccb8418525c1f93285a15ade22ef2626b97fa4d315c56d894210781b287118dfd053954a4bb9ef7cbf329d5c8e19e580636ffe4db97d74aa0d53215f823aa5d63500b31c")
    }
    
    func test_GivenAATransfer_WhenFeeTokenIsNotZeroEncodesCorrectly() {
        let signature = "0x356df69c502ea2339e5e3890ef21ee6f0fb146456c288309fead3dd51f1741d2748e8112ed340e87ba8492311438ef1af95a2fd54ac904b3c2a4364ef4b057881c".web3.hexData!
        let signed = ZKSyncSignedTransaction(
            transaction: with(aaTransfer) { $0.feeToken = EthereumAddress("0x54a14D7559BAF2C8e8Fa504E019d32479739018c")
            }, sigParam: .aa(signature: .init(raw: signature), from: EthereumAddress("0x143b06e4963e5A1dc056a8a41C11746a504d46Cc"))
        )
        
        XCTAssertEqual(signed.raw?.web3.hexString, "0x71f89c1e826f9c8255af9464d0ea4fc60f27e74f1a70aa6f39d403bbe5679385e8d4a510008082011880808201189454a14d7559baf2c8e8fa504e019d32479739018c80c0f85894143b06e4963e5a1dc056a8a41c11746a504d46ccb841356df69c502ea2339e5e3890ef21ee6f0fb146456c288309fead3dd51f1741d2748e8112ed340e87ba8492311438ef1af95a2fd54ac904b3c2a4364ef4b057881c")
    }
    
    func test_GivenAATransfer_WhenSigningWithAAAccount_ThenSignsAndEncodesCorrectly()  {
        let signed = try? aaAccount.sign(zkTransaction: aaTransfer)
        
        XCTAssertEqual(signed?.raw?.web3.hexString,
                       "0x71f89c1e826f9c8255af9464d0ea4fc60f27e74f1a70aa6f39d403bbe5679385e8d4a5100080820118808082011894000000000000000000000000000000000000000080c0f85894143b06e4963e5a1dc056a8a41c11746a504d46ccb8418525c1f93285a15ade22ef2626b97fa4d315c56d894210781b287118dfd053954a4bb9ef7cbf329d5c8e19e580636ffe4db97d74aa0d53215f823aa5d63500b31c")
    }
}
