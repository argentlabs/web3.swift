//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import BigInt
import XCTest
@testable import web3

class EthereumAccount_SignTransactionTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testTransaction2Sign() {
        //https://medium.com/@codetractio/walkthrough-of-an-ethereum-improvement-proposal-eip-6fda3966d171

        let nonce = 9
        let gasPrice = BigUInt(20000000000)
        let gasLimit = BigUInt(21000)
        let to = EthereumAddress("3535353535353535353535353535353535353535")
        let value = BigUInt(1000000000000000000)
        let chainID = 1

        let tx = EthereumTransaction(from: nil, to: to, value: value, data: nil, nonce: nonce, gasPrice: gasPrice, gasLimit: gasLimit, chainId: chainID)

        let account = try! EthereumAccount.init(keyStorage: TestEthereumKeyStorage(privateKey: "0x4646464646464646464646464646464646464646464646464646464646464646"))
        let signed = try! account.sign(transaction: tx)

        let v = signed.v.web3.hexString
        let r = signed.r.web3.hexString
        let s = signed.s.web3.hexString

        XCTAssertEqual(v, "0x25")
        XCTAssertEqual(r, "0x28ef61340bd939bc2195fe537567866003e1a15d3c71ff63e1590620aa636276")
        XCTAssertEqual(s, "0x67cbe9d8997f761aecb703304b3800ccf555c9f3dc64214b297fb1966a3b6d83")

    }

    func testTransactionVitalik1Raw() {

        let nonce = Int(hex: "0x00")!
        let gasPrice = BigUInt(hex: "0x04a817c800")!
        let gasLimit = BigUInt(hex: "0x5208")!
        let to = EthereumAddress("0x3535353535353535353535353535353535353535")
        let value = BigUInt(hex: "0x0")!
        let signature = "0x044852b2a670ade5407e78fb2863c51de9fcb96542a07186fe3aeda6bb8a116d044852b2a670ade5407e78fb2863c51de9fcb96542a07186fe3aeda6bb8a116d25".web3.hexData!
        
        let tx = EthereumTransaction(from: nil, to: to, value: value, data: nil, nonce: nonce, gasPrice: gasPrice, gasLimit: gasLimit, chainId: 37)
        let signed = SignedTransaction(transaction: tx, signature: signature)
        
        let raw = signed.raw!.web3.hexString
        let hash = signed.hash!.web3.hexString

        XCTAssertEqual(raw, "0xf864808504a817c800825208943535353535353535353535353535353535353535808025a0044852b2a670ade5407e78fb2863c51de9fcb96542a07186fe3aeda6bb8a116da0044852b2a670ade5407e78fb2863c51de9fcb96542a07186fe3aeda6bb8a116d")
        XCTAssertEqual(hash, "0xb1e2188bc490908a78184e4818dca53684167507417fdb4c09c2d64d32a9896a")
    }

}
