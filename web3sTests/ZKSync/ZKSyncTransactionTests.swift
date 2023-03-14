//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import XCTest
@testable import web3_zksync
@testable import web3
import BigInt

final class ZKSyncTransactionTests: XCTestCase {
    
    let eoaAccount = try! EthereumAccount(keyStorage: TestEthereumKeyStorage(privateKey: TestConfig.privateKey))
    
    let eoaTransfer = ZKSyncTransaction(
        from: .init(TestConfig.publicKey),
        to: .init("0x64d0eA4FC60f27E74f1a70Aa6f39D403bBe56793"),
        value: BigUInt(hex: "0x5af3107a4000")!,
        data: Data(),
        chainId: TestConfig.ZKSync.chainId,
        nonce: 4,
        gasPrice: BigUInt(hex: "0x05f5e100")!,
        gasLimit: BigUInt(hex: "0x080a22")!
    )
    
    func test_GivenEOATransfer_EncodesCorrectly() {
        let signature = "0x55943b2228183717fd3be583bde0f6ec168247ea8d304eb13b3e7e76ebf6bf2c3c77734e163711c5963ac25a15f95d9ac63b82c2c427fd4eb011c5e3a22f89221b".web3.hexData!
        let signed = ZKSyncSignedTransaction(
            transaction: eoaTransfer, signature: .init(raw: signature)
        )
        XCTAssertEqual(signed.raw?.web3.hexString, "0x71f891048405f5e1008405f5e10083080a229464d0ea4fc60f27e74f1a70aa6f39d403bbe56793865af3107a400080820118808082011894e78e5ecb061fe3dd1672ddda7b5116213b23b99a82c350c0b84155943b2228183717fd3be583bde0f6ec168247ea8d304eb13b3e7e76ebf6bf2c3c77734e163711c5963ac25a15f95d9ac63b82c2c427fd4eb011c5e3a22f89221bc0")
    }
    
    func test_GivenEOATransfer_WhenSigningWithEOAAccount_ThenSignsAndEncodesCorrectly()  {
        let signed = try? eoaAccount.sign(zkTransaction: eoaTransfer)
        
        XCTAssertEqual(signed?.raw?.web3.hexString,
                       "0x71f891048405f5e1008405f5e10083080a229464d0ea4fc60f27e74f1a70aa6f39d403bbe56793865af3107a400080820118808082011894e78e5ecb061fe3dd1672ddda7b5116213b23b99a82c350c0b841c956ba7bfdf54a6d3f3b21c51465ad37df22b6258835b6e162259d6d3eec02ae11f9d17c3aafd47df49bd77e33befed87bbaff44e4c497228bfa8bcc9fa64bc31bc0")
    }
}
