//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import XCTest
@testable import web3

class KeyUtilTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testPrivateKeyGeneration() {
        if let privateKey = KeyUtil.generatePrivateKeyData() {
            XCTAssertEqual(privateKey.count, 32)
        }
    }

    func testPublicKeyFromPrivateKeyGeneration() {
        let privateKeyHex = "77e15a8064e0a080fcf845694e0e9eaa3dea29659738f7aa2c8e3b26b48d9d7f"
        guard let privateKey = privateKeyHex.web3.hexData else {
            XCTFail("Private key data incorrect")
            return
        }

        let publicKey = try! KeyUtil.generatePublicKey(from: privateKey)
        let publicKeyHex = publicKey.web3.hexString

        XCTAssertEqual(publicKeyHex, "0x5544fbcbda6327d51982e9778615010423502564348d72f8adf96aeb0801c4988aea911f7080518b3a5520465f81358126f0d5120e6e1af858f653618a9c297b")
    }

    func testAddressFromPublicKeyGeneration() {
        let privateKeyHex = "77e15a8064e0a080fcf845694e0e9eaa3dea29659738f7aa2c8e3b26b48d9d7f"
        guard let privateKey = privateKeyHex.web3.hexData else {
            XCTFail("Private key data incorrect")
            return
        }

        let publicKey = try! KeyUtil.generatePublicKey(from: privateKey)
        let address = KeyUtil.generateAddress(from: publicKey)

        XCTAssertEqual(address, "0x751e735a83a8142c1b9dc722ef559b898f1d77fa")
    }
    
    func testRecoverPublicKey() {
        let account = try! EthereumAccount(keyStorage: TestEthereumKeyStorage(privateKey: "0x2639f727ded571d584643895d43d02a7a190f8249748a2c32200cfc12dde7173"))
        let signature = try! account.sign(message: "Hello message!")

        let address = try! KeyUtil.recoverPublicKey(message: "Hello message!".web3.keccak256, signature: signature)

        XCTAssertEqual(address, account.address.asString().lowercased())
    }
    
    func testRecoverPublicKeyMultiple() {
        let storage = TestEthereumMultipleKeyStorage(privateKey: "0x2639f727ded571d584643895d43d02a7a190f8249748a2c32200cfc12dde7173")
        let account = try! EthereumAccount(addressString: TestConfig.publicKey, keyStorage: storage)
        let signature = try! account.sign(message: "Hello message!")

        let address = try! KeyUtil.recoverPublicKey(message: "Hello message!".web3.keccak256, signature: signature)

        XCTAssertEqual(address, account.address.asString().lowercased())
    }
}
