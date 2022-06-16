//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation

public protocol EthereumAccountProtocol {
    var address: EthereumAddress { get }
    
    func sign(data: Data) throws -> Data
    func sign(hash: String) throws -> Data
    func sign(hex: String) throws -> Data
    func sign(message: Data) throws -> Data
    func sign(message: String) throws -> Data
    func sign(transaction: EthereumTransaction) throws -> SignedTransaction
}

public enum EthereumAccountError: Error {
    case createAccountError
    case importAccountError
    case loadAccountError
    case signError
}

public class EthereumAccount: EthereumAccountProtocol {
    private let privateKeyData: Data
    private let publicKeyData: Data
    
    public lazy var publicKey: String = {
        return self.publicKeyData.web3.hexString
    }()
    
    public lazy var address: EthereumAddress = {
        return KeyUtil.generateAddress(from: self.publicKeyData)
    }()
    
    required public init(keyStorage: EthereumKeyStorageProtocol, keystorePassword password: String) throws {
        do {
            let decodedKey = try keyStorage.loadAndDecryptPrivateKey(keystorePassword: password)
            self.privateKeyData = decodedKey
            self.publicKeyData = try KeyUtil.generatePublicKey(from: decodedKey)
        } catch let error {
            print("Error loading key data: \(error)")
            throw EthereumAccountError.loadAccountError
        }
    }
    
    required public init(keyStorage: EthereumKeyStorageProtocol) throws {
        do {
            let data = try keyStorage.loadPrivateKey()
            self.privateKeyData = data
            self.publicKeyData = try KeyUtil.generatePublicKey(from: data)
        } catch {
            throw EthereumAccountError.loadAccountError
        }
    }
    
    public static func create(keyStorage: EthereumKeyStorageProtocol, keystorePassword password: String) throws -> EthereumAccount {
        guard let privateKey = KeyUtil.generatePrivateKeyData() else {
            throw EthereumAccountError.createAccountError
        }
        
        do {
            try keyStorage.encryptAndStorePrivateKey(key: privateKey, keystorePassword: password)
            return try self.init(keyStorage: keyStorage, keystorePassword: password)
        } catch {
            throw EthereumAccountError.createAccountError
        }
    }

    public static func importAccount(keyStorage: EthereumKeyStorageProtocol, privateKey: String, keystorePassword password: String) throws -> EthereumAccount {
        guard let privateKey = privateKey.web3.hexData else {
            throw EthereumAccountError.importAccountError
        }
        do {
            try keyStorage.encryptAndStorePrivateKey(key: privateKey, keystorePassword: password)
            return try self.init(keyStorage: keyStorage, keystorePassword: password)
        } catch {
            throw EthereumAccountError.importAccountError
        }
    }

    public func sign(data: Data) throws -> Data {
        return try KeyUtil.sign(message: data, with: self.privateKeyData, hashing: true)
    }
    
    public func sign(hex: String) throws -> Data {
        if let data = Data.init(hex: hex) {
            return try KeyUtil.sign(message: data, with: self.privateKeyData, hashing: true)
        } else {
            throw EthereumAccountError.signError
        }
    }
    
    public func sign(hash: String) throws -> Data {
        if let data = hash.web3.hexData {
            return try KeyUtil.sign(message: data, with: self.privateKeyData, hashing: false)
        } else {
            throw EthereumAccountError.signError
        }
    }
    
    public func sign(message: Data) throws -> Data {
        return try KeyUtil.sign(message: message, with: self.privateKeyData, hashing: false)
    }
    
    public func sign(message: String) throws -> Data {
        if let data = message.data(using: .utf8) {
            return try KeyUtil.sign(message: data, with: self.privateKeyData, hashing: true)
        } else {
            throw EthereumAccountError.signError
        }
    }
    
    public func signMessage(message: Data) throws -> String {
        let prefix = "\u{19}Ethereum Signed Message:\n\(String(message.count))"
        guard var data = prefix.data(using: .ascii) else {
            throw EthereumAccountError.signError
        }
        data.append(message)
        let hash = data.web3.keccak256
        
        guard var signed = try? self.sign(message: hash) else {
            throw EthereumAccountError.signError
            
        }
        
        // Check last char (v)
        guard var last = signed.popLast() else {
            throw EthereumAccountError.signError
            
        }
        
        if last < 27 {
            last += 27
        }
        
        signed.append(last)
        return signed.web3.hexString
    }
    
    public func signMessage(message: TypedData) throws -> String {
        let hash = try message.signableHash()
        
        guard var signed = try? self.sign(message: hash) else {
            throw EthereumAccountError.signError
            
        }
        
        // Check last char (v)
        guard var last = signed.popLast() else {
            throw EthereumAccountError.signError
            
        }
        
        if last < 27 {
            last += 27
        }
        
        signed.append(last)
        return signed.web3.hexString
    }
}
