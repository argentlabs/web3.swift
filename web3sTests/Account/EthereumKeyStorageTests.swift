//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import XCTest
@testable import web3

class EthereumKeyStorageTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testStoreLocalPrivateKey() {
        let randomData = Data.randomOfLength(256)!
        let keyStorage = EthereumKeyLocalStorage()

        do {
            let ethereumAddress = EthereumAddress(TestConfig.publicKey)
            try keyStorage.storePrivateKey(key: randomData, with: ethereumAddress)
        } catch {
            XCTFail("Failed to save private key. Ensure key is valid in TestConfig.swift")
        }
    }

    func testStoreAndLoadLocalPrivateKey() {
        let randomData = Data.randomOfLength(256)!
        let keyStorage = EthereumKeyLocalStorage()
        let ethereumAddress = EthereumAddress(TestConfig.publicKey)
        do {
            try keyStorage.storePrivateKey(key: randomData, with: ethereumAddress)
            let storedData = try keyStorage.loadPrivateKey(for: ethereumAddress)
            XCTAssertEqual(randomData, storedData)
        } catch {
            XCTFail("Failed to save private key. Ensure key is valid in TestConfig.swift")
        }
    }
    
    func testEncryptAndStorePrivateKey() {
        let randomData = Data.randomOfLength(256)!
        let keyStorage = EthereumKeyLocalStorage() as EthereumKeyStorageProtocol
        let password = "myP4ssw0rD"

        do {
            try keyStorage.encryptAndStorePrivateKey(key: randomData, keystorePassword: password)
            let decrypted = try keyStorage.loadAndDecryptPrivateKey(keystorePassword: password)
            XCTAssertEqual(decrypted, randomData)
        } catch let error {
            XCTFail("Failed to encrypt and store private key with error: \(error)")
        }
    }

    func testEncryptAndStorePrivateKeyMultiple() {
        let randomData = Data.randomOfLength(256)!
        let keyStorage = EthereumKeyLocalStorage() as EthereumMultipleKeyStorageProtocol
        let password = "myP4ssw0rD"

        do {
            _ = KeyUtil.generateAddress(from: randomData)
            try keyStorage.encryptAndStorePrivateKey(key: randomData, keystorePassword: password)
            let publicKey = try KeyUtil.generatePublicKey(from: randomData)
            let address = KeyUtil.generateAddress(from: publicKey)
            let decrypted = try keyStorage.loadAndDecryptPrivateKey(for: address, keystorePassword: password)
            XCTAssertEqual(decrypted, randomData)
        } catch let error {
            XCTFail("Failed to encrypt and store private key with error: \(error)")
        }
    }
    
    func testDeleteAllPrivateKeys() {
        let keyStorage = EthereumKeyLocalStorage() as EthereumMultipleKeyStorageProtocol
        let numberOfCreatedAddresses = Int.random(in: 1...5)
        do {
            for _ in 1...numberOfCreatedAddresses {
                _ = try EthereumAccount.create(keyStorage: keyStorage, keystorePassword: "PASSWORD")
            }
            try keyStorage.deleteAllKeys()
            let countAfterDeleting = try keyStorage.fetchAccounts()
            XCTAssert(countAfterDeleting.count == .zero)
        } catch let error {
            XCTFail("Failed to delete all private keys: \(error)")
        }
    }
}
