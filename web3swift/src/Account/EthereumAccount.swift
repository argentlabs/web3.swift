//
//  EthereumAccount.swift
//  web3swift
//
//  Created by Julien Niset on 15/02/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation

protocol EthereumAccountProtocol {
    var address: EthereumAddress { get }
    
    // For Keystore handling
    init?(keyStorage: EthereumKeyStorageProtocol, keystorePassword: String) throws
    static func create(keyStorage: EthereumKeyStorageProtocol, keystorePassword password: String) throws -> EthereumAccount
    
    // For non-Keystore formats. This is not recommended, however some apps may wish to implement their own storage.
    init(keyStorage: EthereumKeyStorageProtocol) throws
    
    func sign(data: Data) throws -> Data
    func sign(hash: String) throws -> Data
    func sign(hex: String) throws -> Data
    func sign(message: Data) throws -> Data
    func sign(message: String) throws -> Data
    func sign(transaction: EthereumTransaction) throws -> SignedTransaction
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
            let data = try keyStorage.loadPrivateKey()
            if let decodedKey = try? KeystoreUtil.decode(data: data, password: password) {
                self.privateKeyData = decodedKey
                self.publicKeyData = try KeyUtil.generatePublicKey(from: decodedKey)
            } else {
                print("Error decrypting key data")
                throw Web3Error.loadAccountError
            }
        } catch {
           throw Web3Error.loadAccountError
        }
    }
    
    required public init(keyStorage: EthereumKeyStorageProtocol) throws {
        do {
            let data = try keyStorage.loadPrivateKey()
            self.privateKeyData = data
            self.publicKeyData = try KeyUtil.generatePublicKey(from: data)
        } catch {
            throw Web3Error.loadAccountError
        }
    }
    
    public static func create(keyStorage: EthereumKeyStorageProtocol, keystorePassword password: String) throws -> EthereumAccount {
        guard let privateKey = KeyUtil.generatePrivateKeyData() else {
            throw Web3Error.createAccountError
        }
        
        do {
            let encodedData = try KeystoreUtil.encode(privateKey: privateKey, password: password)
            try keyStorage.storePrivateKey(key: encodedData)
            return try self.init(keyStorage: keyStorage, keystorePassword: password)
        } catch {
            throw Web3Error.createAccountError
        }
    }
    
    public func sign(data: Data) throws -> Data {
        return try KeyUtil.sign(message: data, with: self.privateKeyData, hashing: true)
    }
    
    public func sign(hex: String) throws -> Data {
        if let data = Data.init(hex: hex) {
            return try KeyUtil.sign(message: data, with: self.privateKeyData, hashing: true)
        } else {
            throw Web3Error.signError
        }
    }
    
    public func sign(hash: String) throws -> Data {
        if let data = hash.web3.hexData {
            return try KeyUtil.sign(message: data, with: self.privateKeyData, hashing: false)
        } else {
            throw Web3Error.signError
        }
    }
    
    public func sign(message: Data) throws -> Data {
        return try KeyUtil.sign(message: message, with: self.privateKeyData, hashing: false)
    }
    
    public func sign(message: String) throws -> Data {
        if let data = message.data(using: .utf8) {
            return try KeyUtil.sign(message: data, with: self.privateKeyData, hashing: true)
        } else {
            throw Web3Error.signError
        }
    }
    
    public func signMessage(message: Data) throws -> String {
        let prefix = "\u{19}Ethereum Signed Message:\n\(String(message.count))"
        guard var data = prefix.data(using: .ascii) else {
            throw Web3Error.signError
        }
        data.append(message)
        let hash = data.web3.keccak256
        
        guard var signed = try? self.sign(message: hash) else {
            throw Web3Error.signError
            
        }
        
        // Check last char (v)
        guard var last = signed.popLast() else {
            throw Web3Error.signError
            
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
            throw Web3Error.signError
            
        }
        
        // Check last char (v)
        guard var last = signed.popLast() else {
            throw Web3Error.signError
            
        }
        
        if last < 27 {
            last += 27
        }
        
        signed.append(last)
        return signed.web3.hexString
    }
}
