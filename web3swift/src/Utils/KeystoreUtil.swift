//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation

protocol KeystoreUtilProtocol {
    static func encode(privateKey: Data, password: String) throws -> Data
    static func decode(data: Data, password: String) throws -> Data
}

enum KeystoreUtilError: Error {
    case corruptedKeystore
    case decodeFailed
    case encodeFailed
    case unknown
}

class KeystoreUtil: KeystoreUtilProtocol {
    private static let dklen = 32
    private static let dkround = 262144
    
    static func encode(privateKey: Data, password: String) throws -> Data {
        guard let salt = Data.randomOfLength(16) else {
            throw KeystoreUtilError.unknown
        }
        
        guard let iv = Data.randomOfLength(16) else {
            throw KeystoreUtilError.unknown
        }
        
        return try encode(privateKey: privateKey, password: password, salt: salt, iv: iv)
    }
    
    static func encode(privateKey: Data, password: String, salt: Data, iv: Data) throws -> Data {
        
        // derive address from private key
        let publicKeyData = try KeyUtil.generatePublicKey(from: privateKey)
        let address = KeyUtil.generateAddress(from: publicKeyData)
        
        // derive encryption key for keystore
        let keyDerivator = KeyDerivator(algorithm: .pbkdf2sha256, dklen: self.dklen, round: self.dkround)
        guard let derivedKey = keyDerivator.deriveKey(key: password, salt: salt) else {
            throw KeystoreUtilError.unknown
        }
        
        // encrypt private key
        let encKey = derivedKey.subdata(in: 0..<16)
        let encryptor = Aes128Util(key: encKey, iv: iv)
        let ciphertext = encryptor.xcrypt(input: privateKey)
        
        // compute mac
        let macKey = derivedKey.subdata(in: 16..<32)
        let concat = macKey + ciphertext
        let mac = concat.web3.keccak256
        
        // create keystore
        let crypto = KeystoreFileCrypto(
            cipher: "aes-128-ctr",
            cipherparams: KeystoreFileCryptoCipherParams(iv: iv.web3.hexString.web3.noHexPrefix),
            ciphertext: ciphertext.web3.hexString.web3.noHexPrefix,
            kdf: keyDerivator.algorithm.function(),
            kdfparams: KeystoreFileCryptoKdfParams(c: self.dkround, dklen: self.dklen, prf: keyDerivator.algorithm.hash(), salt: salt.web3.hexString.web3.noHexPrefix),
            mac: mac.web3.hexString.web3.noHexPrefix)
        
        let keystore = KeystoreFile(crypto: crypto, address: address, version: 3)
        
        // encode json
        guard let data = try? JSONEncoder().encode(keystore) else {
            throw KeystoreUtilError.encodeFailed
        }

        return data
    }
    
    static func decode(data: Data, password: String) throws -> Data {
        
        // decode json string
        guard let keystore = try? JSONDecoder().decode(KeystoreFile.self, from: data) else {
            throw KeystoreUtilError.decodeFailed
        }
        
        // derive encryption key from keystore
        guard let salt = Data(hex: keystore.crypto.kdfparams.salt) else {
            throw KeystoreUtilError.decodeFailed
        }
        let keyDerivator = KeyDerivator(algorithm: .pbkdf2sha256, dklen: dklen, round: self.dkround)
        guard let derivedKey = keyDerivator.deriveKey(key: password, salt: salt) else {
            throw KeystoreUtilError.decodeFailed
        }
        
        // read ciphertext
        guard let ciphertext = Data(hex: keystore.crypto.ciphertext) else {
            throw KeystoreUtilError.decodeFailed
        }
        
        // verify mac
        let macKey = derivedKey.subdata(in: 16..<32)
        let concat = macKey + ciphertext
        let mac = concat.web3.keccak256
        guard mac.web3.hexString.web3.noHexPrefix == keystore.crypto.mac else {
            throw KeystoreUtilError.corruptedKeystore
        }
        
        // decrypt ciphertext with encryption key
        let encKey = derivedKey.subdata(in: 0..<16)
        let iv = keystore.crypto.cipherparams.iv.web3.hexData
        let decryptor = Aes128Util(key: encKey, iv: iv)
        let privateKey = decryptor.xcrypt(input: ciphertext)
        
        return privateKey
    }
}

struct KeystoreFile: Codable {
    let crypto: KeystoreFileCrypto
    let address: EthereumAddress
    let version: Int
}

struct KeystoreFileCrypto: Codable {
    let cipher: String
    let cipherparams: KeystoreFileCryptoCipherParams
    let ciphertext: String
    let kdf: String
    let kdfparams: KeystoreFileCryptoKdfParams
    let mac: String
}

struct KeystoreFileCryptoCipherParams: Codable {
    let iv: String
}

struct KeystoreFileCryptoKdfParams: Codable {
    let c: Int
    let dklen: Int
    let prf: String
    let salt: String
}
