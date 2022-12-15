//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Logging
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
    private let logger: Logger

    public let publicKey: String
    public let address: EthereumAddress

    required public init(addressString: String, keyStorage: EthereumKeyStorageProtocol, keystorePassword password: String, logger: Logger? = nil) throws {
        self.logger = logger ?? Logger(label: "web3.swift.eth-account")
        do {
            let address = EthereumAddress(addressString)
            let decodedKey = try keyStorage.loadAndDecryptPrivateKey(for: address, keystorePassword: password)
            self.privateKeyData = decodedKey
            self.publicKeyData = try KeyUtil.generatePublicKey(from: decodedKey)
            self.publicKey = publicKeyData.web3.hexString
            self.address = KeyUtil.generateAddress(from: publicKeyData)
        } catch {
            self.logger.warning("Error loading key data: \(error)")
            throw EthereumAccountError.loadAccountError
        }
    }

    required public init(addressString: String, keyStorage: EthereumKeyStorageProtocol, logger: Logger? = nil) throws {
        self.logger = logger ?? Logger(label: "web3.swift.eth-account")
        do {
            let address = EthereumAddress(addressString)
            let data = try keyStorage.loadPrivateKey(for: address)
            self.privateKeyData = data
            self.publicKeyData = try KeyUtil.generatePublicKey(from: data)
            self.publicKey = publicKeyData.web3.hexString
            self.address = KeyUtil.generateAddress(from: publicKeyData)
        } catch {
            throw EthereumAccountError.loadAccountError
        }
    }

    required public init(addressString: String, keyStorage: EthereumMultipleKeyStorageProtocol, keystorePassword password: String, logger: Logger? = nil) throws {
        self.logger = logger ?? Logger(label: "web3.swift.eth-account")
        do {
            let address = EthereumAddress(addressString)
            let decodedKey = try keyStorage.loadAndDecryptPrivateKey(for: address, keystorePassword: password)
            self.privateKeyData = decodedKey
            self.publicKeyData = try KeyUtil.generatePublicKey(from: decodedKey)
            self.publicKey = publicKeyData.web3.hexString
            self.address = KeyUtil.generateAddress(from: publicKeyData)
        } catch {
            self.logger.warning("Error loading key data: \(error)")
            throw EthereumAccountError.loadAccountError
        }
    }

    required public init(addressString: String, keyStorage: EthereumMultipleKeyStorageProtocol, logger: Logger? = nil) throws {
        self.logger = logger ?? Logger(label: "web3.swift.eth-account")
        do {
            let address = EthereumAddress(addressString)
            let data = try keyStorage.loadPrivateKey(for: address)
            self.privateKeyData = data
            self.publicKeyData = try KeyUtil.generatePublicKey(from: data)
            self.publicKey = publicKeyData.web3.hexString
            self.address = KeyUtil.generateAddress(from: publicKeyData)
        } catch {
            throw EthereumAccountError.loadAccountError
        }
    }

    public static func create(addingTo keyStorage: EthereumMultipleKeyStorageProtocol, keystorePassword password: String) throws -> EthereumAccount {
        guard let privateKey = KeyUtil.generatePrivateKeyData() else {
            throw EthereumAccountError.createAccountError
        }

        do {
            try keyStorage.encryptAndStorePrivateKey(key: privateKey, keystorePassword: password)
            let publicKey = try KeyUtil.generatePublicKey(from: privateKey)
            let address = KeyUtil.generateAddress(from: publicKey).value
            return try self.init(addressString: address, keyStorage: keyStorage, keystorePassword: password)
        } catch {
            throw EthereumAccountError.createAccountError
        }
    }

    public static func create(replacing keyStorage: EthereumKeyStorageProtocol, keystorePassword password: String) throws -> EthereumAccount {
        guard let privateKey = KeyUtil.generatePrivateKeyData() else {
            throw EthereumAccountError.createAccountError
        }

        do {
            try keyStorage.encryptAndStorePrivateKey(key: privateKey, keystorePassword: password)
            let publicKey = try KeyUtil.generatePublicKey(from: privateKey)
            let address = KeyUtil.generateAddress(from: publicKey).value
            return try self.init(addressString: address, keyStorage: keyStorage, keystorePassword: password)
        } catch {
            throw EthereumAccountError.createAccountError
        }
    }

    public static func importAccount(addingTo keyStorage: EthereumMultipleKeyStorageProtocol, privateKey: String, keystorePassword password: String) throws -> EthereumAccount {
        guard let privateKey = privateKey.web3.hexData else {
            throw EthereumAccountError.importAccountError
        }
        do {
            try keyStorage.encryptAndStorePrivateKey(key: privateKey, keystorePassword: password)
            let publicKey = try KeyUtil.generatePublicKey(from: privateKey)
            let address = KeyUtil.generateAddress(from: publicKey).value
            return try self.init(addressString: address, keyStorage: keyStorage, keystorePassword: password)
        } catch {
            throw EthereumAccountError.importAccountError
        }
    }

    public static func importAccount(replacing keyStorage: EthereumKeyStorageProtocol, privateKey: String, keystorePassword password: String) throws -> EthereumAccount {
        guard let privateKey = privateKey.web3.hexData else {
            throw EthereumAccountError.importAccountError
        }
        do {
            try keyStorage.encryptAndStorePrivateKey(key: privateKey, keystorePassword: password)
            let publicKey = try KeyUtil.generatePublicKey(from: privateKey)
            let address = KeyUtil.generateAddress(from: publicKey).value
            return try self.init(addressString: address, keyStorage: keyStorage, keystorePassword: password)
        } catch {
            throw EthereumAccountError.importAccountError
        }
    }

    public func sign(data: Data) throws -> Data {
        try KeyUtil.sign(message: data, with: privateKeyData, hashing: true)
    }

    public func sign(hex: String) throws -> Data {
        if let data = Data(hex: hex) {
            return try KeyUtil.sign(message: data, with: privateKeyData, hashing: true)
        } else {
            throw EthereumAccountError.signError
        }
    }

    public func sign(hash: String) throws -> Data {
        if let data = hash.web3.hexData {
            return try KeyUtil.sign(message: data, with: privateKeyData, hashing: false)
        } else {
            throw EthereumAccountError.signError
        }
    }

    public func sign(message: Data) throws -> Data {
        try KeyUtil.sign(message: message, with: privateKeyData, hashing: false)
    }

    public func sign(message: String) throws -> Data {
        if let data = message.data(using: .utf8) {
            return try KeyUtil.sign(message: data, with: privateKeyData, hashing: true)
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

        guard var signed = try? sign(message: hash) else {
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

        guard var signed = try? sign(message: hash) else {
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
