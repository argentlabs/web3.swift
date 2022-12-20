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

    func testStoreLocalPrivateKey() async {
        let randomData = Data.randomOfLength(256)!
        let keyStorage = EthereumKeyLocalStorage()

        do {
            let ethereumAddress = EthereumAddress(TestConfig.publicKey)
            try await keyStorage.storePrivateKey(key: randomData, with: ethereumAddress)
        } catch {
            XCTFail("Failed to save private key. Ensure key is valid in TestConfig.swift")
        }
    }

    func testStoreAndLoadLocalPrivateKey() async {
        let randomData = Data.randomOfLength(256)!
        let keyStorage = EthereumKeyLocalStorage()
        let ethereumAddress = EthereumAddress(TestConfig.publicKey)
        do {
            try await keyStorage.storePrivateKey(key: randomData, with: ethereumAddress)
            let storedData = try await keyStorage.loadPrivateKey(for: ethereumAddress)
            XCTAssertEqual(randomData, storedData)
        } catch {
            XCTFail("Failed to save private key. Ensure key is valid in TestConfig.swift")
        }
    }
    
    func testEncryptAndStorePrivateKey() async {
        let randomData = Data.randomOfLength(256)!
        let keyStorage = EthereumKeyLocalStorage() as EthereumKeyStorageProtocol
        let password = "myP4ssw0rD"

        do {
            try await keyStorage.encryptAndStorePrivateKey(key: randomData, keystorePassword: password)
            let publicKey = try KeyUtil.generatePublicKey(from: randomData)
            let address = KeyUtil.generateAddress(from: publicKey)
            let decrypted = try await keyStorage.loadAndDecryptPrivateKey(for: address, keystorePassword: password)
            XCTAssertEqual(decrypted, randomData)
        } catch let error {
            XCTFail("Failed to encrypt and store private key with error: \(error)")
        }
    }

    func testEncryptAndStorePrivateKeyMultiple() async {
        let randomData = Data.randomOfLength(256)!
        let keyStorage = EthereumKeyLocalStorage() as EthereumMultipleKeyStorageProtocol
        let password = "myP4ssw0rD"

        do {
            _ = KeyUtil.generateAddress(from: randomData)
            try await keyStorage.encryptAndStorePrivateKey(key: randomData, keystorePassword: password)
            let publicKey = try KeyUtil.generatePublicKey(from: randomData)
            let address = KeyUtil.generateAddress(from: publicKey)
            let decrypted = try await keyStorage.loadAndDecryptPrivateKey(for: address, keystorePassword: password)
            XCTAssertEqual(decrypted, randomData)
        } catch let error {
            XCTFail("Failed to encrypt and store private key with error: \(error)")
        }
    }
    
    func testDeleteAllPrivateKeys() async {
        let keyStorage = EthereumKeyLocalStorage()
        do {
            _ = try await EthereumAccount.create(settingTo: keyStorage)
            _ = try await EthereumAccount.create(settingTo: keyStorage)
            _ = try await EthereumAccount.create(settingTo: keyStorage)
            try await keyStorage.deleteAllKeys()
            let countAfterDeleting = try await keyStorage.fetchAccounts()
            XCTAssertEqual(countAfterDeleting.count, 0)
        } catch let error {
            XCTFail("Failed to delete all private keys: \(error)")
        }
    }
}
