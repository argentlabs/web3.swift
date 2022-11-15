//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import XCTest
@testable import web3

class KeystoreUtilTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testKeystoreEncode() {
        let password = "testpassword"
        let salt = "ae3cd4e7013836a3df6bd7241b12db061dbe2c6785853cce422d148a624ce0bd".web3.hexData!
        let iv = "6087dab2f9fdbbfaddc31a909735c1e6".web3.hexData!
        let privateKey = "7a28b5ba57c53603b0b07b56bba752f7784bf506fa95edc395f5cf6c7514fe9d".web3.hexData!

        let encryptedData = try! KeystoreUtil.encode(privateKey: privateKey, password: password, salt: salt, iv: iv)
        let encryptedFile = try! JSONDecoder().decode(KeystoreFile.self, from: encryptedData)

        let expectedJson = """
            {"crypto":{"cipher":"aes-128-ctr","cipherparams":{"iv":"6087dab2f9fdbbfaddc31a909735c1e6"},"ciphertext":"5318b4d5bcd28de64ee5559e671353e16f075ecae9f99c7a79a38af5f869aa46","kdf":"pbkdf2","kdfparams":{"c":262144,"dklen":32,"prf":"hmac-sha256","salt":"ae3cd4e7013836a3df6bd7241b12db061dbe2c6785853cce422d148a624ce0bd"},"mac":"517ead924a9d0dc3124507e3393d175ce3ff7c1e96529c6c555ce9e51205e9b2"},"address":"0x008aeeda4d805471df9b2a5b0f38a0c3bcba786b","version":3}
""".data(using: .utf8)!

        let expectedFile = try! JSONDecoder().decode(KeystoreFile.self, from: expectedJson)

        XCTAssertEqual(encryptedFile, expectedFile)
    }

    func testKeystoreDecode() {

        let jsonData = """
{"crypto":{"cipher":"aes-128-ctr","cipherparams":{"iv":"6087dab2f9fdbbfaddc31a909735c1e6"},"ciphertext":"5318b4d5bcd28de64ee5559e671353e16f075ecae9f99c7a79a38af5f869aa46","kdf":"pbkdf2","kdfparams":{"c":262144,"dklen":32,"prf":"hmac-sha256","salt":"ae3cd4e7013836a3df6bd7241b12db061dbe2c6785853cce422d148a624ce0bd"},"mac":"517ead924a9d0dc3124507e3393d175ce3ff7c1e96529c6c555ce9e51205e9b2"},"address":"0x008aeeda4d805471df9b2a5b0f38a0c3bcba786b","version":3}
""".data(using: .utf8)!

        let privateKeyData = try! KeystoreUtil.decode(data: jsonData, password: "testpassword")

        XCTAssertEqual(privateKeyData.web3.hexString.web3.noHexPrefix, "7a28b5ba57c53603b0b07b56bba752f7784bf506fa95edc395f5cf6c7514fe9d")
    }

}

extension KeystoreFile: Equatable {
    public static func == (lhs: KeystoreFile, rhs: KeystoreFile) -> Bool {
        return lhs.crypto == rhs.crypto && lhs.address == rhs.address && lhs.version == rhs.version
    }
}

extension KeystoreFileCrypto: Equatable {
    public static func == (lhs: KeystoreFileCrypto, rhs: KeystoreFileCrypto) -> Bool {
        return lhs.cipher == rhs.cipher && lhs.cipherparams == rhs.cipherparams && lhs.ciphertext == rhs.ciphertext && lhs.kdf == rhs.kdf && lhs.kdfparams == rhs.kdfparams && lhs.mac == rhs.mac
    }
}

extension KeystoreFileCryptoCipherParams: Equatable {
    public static func == (lhs: KeystoreFileCryptoCipherParams, rhs: KeystoreFileCryptoCipherParams) -> Bool {
        return lhs.iv == rhs.iv
    }
}

extension KeystoreFileCryptoKdfParams: Equatable {
    public static func == (lhs: KeystoreFileCryptoKdfParams, rhs: KeystoreFileCryptoKdfParams) -> Bool {
        return lhs.c == rhs.c && lhs.dklen == rhs.dklen && lhs.prf == rhs.prf && lhs.salt == rhs.salt
    }
}
