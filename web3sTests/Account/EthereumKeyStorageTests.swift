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
    
    // These two go through KeyUtil.generatePublicKey, so the key has to be a real 32 byte
    // secp256k1 scalar. They used to pass 256 random bytes and rely on the first 32 being
    // taken silently.
    func testEncryptAndStorePrivateKey() {
        let privateKey = "2639f727ded571d584643895d43d02a7a190f8249748a2c32200cfc12dde7173".web3.hexData!
        let keyStorage = EthereumKeyLocalStorage() as EthereumSingleKeyStorageProtocol
        let password = "myP4ssw0rD"

        do {
            try keyStorage.encryptAndStorePrivateKey(key: privateKey, keystorePassword: password)
            let decrypted = try keyStorage.loadAndDecryptPrivateKey(keystorePassword: password)
            XCTAssertEqual(decrypted, privateKey)
        } catch let error {
            XCTFail("Failed to encrypt and store private key with error: \(error)")
        }
    }

    func testEncryptAndStorePrivateKeyMultiple() {
        let privateKey = "2639f727ded571d584643895d43d02a7a190f8249748a2c32200cfc12dde7173".web3.hexData!
        let keyStorage = EthereumKeyLocalStorage() as EthereumMultipleKeyStorageProtocol
        let password = "myP4ssw0rD"

        do {
            try keyStorage.encryptAndStorePrivateKey(key: privateKey, keystorePassword: password)
            let publicKey = try KeyUtil.generatePublicKey(from: privateKey)
            let address = KeyUtil.generateAddress(from: publicKey)
            let decrypted = try keyStorage.loadAndDecryptPrivateKey(for: address, keystorePassword: password)
            XCTAssertEqual(decrypted, privateKey)
        } catch let error {
            XCTFail("Failed to encrypt and store private key with error: \(error)")
        }
    }
    
    // A key file written by NSKeyedArchiver.archiveRootObject(_:toFile:) — the call this library
    // used before moving to archivedData(withRootObject:requiringSecureCoding:). Anyone upgrading
    // has one of these on disk, so it has to keep loading.
    func testLoadsAPrivateKeyArchivedByAnEarlierVersion() throws {
        let legacyArchive = Data(base64Encoded: "YnBsaXN0MDDUAQIDBAUGBwpYJHZlcnNpb25ZJGFyY2hpdmVyVCR0b3BYJG9iamVjdHMSAAGGoF8QD05TS2V5ZWRBcmNoaXZlctEICVRyb290gAGiCwxVJG51bGxPECArfhUWKK7Spqv3FYgJz0883q2+7wARIjNEVWZ3iJmquwgRGiQpMjdJTFFTVlwAAAAAAAABAQAAAAAAAAANAAAAAAAAAAAAAAAAAAAAfw==")!
        let expected = Data([
            0x2b, 0x7e, 0x15, 0x16, 0x28, 0xae, 0xd2, 0xa6, 0xab, 0xf7, 0x15, 0x88, 0x09, 0xcf, 0x4f, 0x3c,
            0xde, 0xad, 0xbe, 0xef, 0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88, 0x99, 0xaa, 0xbb
        ])

        let url = try XCTUnwrap(FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first)
            .appendingPathComponent("ethereumkey")
        try legacyArchive.write(to: url)

        let keyStorage = EthereumKeyLocalStorage() as EthereumSingleKeyStorageProtocol

        XCTAssertEqual(try keyStorage.loadPrivateKey(), expected)
    }

    func testDeleteAllPrivateKeys() {
        let keyStorage = EthereumKeyLocalStorage()
        do {
            _ = try EthereumAccount.create(addingTo: keyStorage, keystorePassword: "PASSWORD")
            _ = try EthereumAccount.create(addingTo: keyStorage, keystorePassword: "PASSWORD")
            _ = try EthereumAccount.create(addingTo: keyStorage, keystorePassword: "PASSWORD")
            try keyStorage.deleteAllKeys()
            let countAfterDeleting = try keyStorage.fetchAccounts()
            XCTAssertEqual(countAfterDeleting.count, 0)
        } catch let error {
            XCTFail("Failed to delete all private keys: \(error)")
        }
    }
}
