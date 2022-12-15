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
    case addressesDoesNotMatch
    case createAccountError
    case importAccountError
    case loadAccountError
    case signError
}

public class EthereumAccount: EthereumAccountProtocol {
    private let keyStorage: EthereumKeyStorageProtocol
    private let logger: Logger

    public let publicKey: String
    public let address: EthereumAddress

    required public init(address: EthereumAddress, keyStorage: EthereumKeyStorageProtocol, logger: Logger? = nil) {
        self.keyStorage = keyStorage
        self.logger = logger ?? Logger(label: "web3.swift.eth-account")
        self.address = address
        self.publicKey = address.value.web3.withHexPrefix
    }

    public static func create(settingTo keyStorage: EthereumKeyStorageProtocol) throws -> EthereumAccount {
        guard let privateKey = KeyUtil.generatePrivateKeyData() else {
            throw EthereumAccountError.createAccountError
        }

        do {
            let publicKey = try KeyUtil.generatePublicKey(from: privateKey)
            let address = KeyUtil.generateAddress(from: publicKey)
            try keyStorage.storePrivateKey(key: privateKey, with: address)
            return self.init(address: address, keyStorage: keyStorage)
        } catch {
            throw EthereumAccountError.createAccountError
        }
    }

    public static func importAccount(settingTo keyStorage: EthereumKeyStorageProtocol, privateKey: String) throws -> EthereumAccount {
        guard let privateKey = privateKey.web3.hexData else {
            throw EthereumAccountError.importAccountError
        }
        do {
            let publicKey = try KeyUtil.generatePublicKey(from: privateKey)
            let address = KeyUtil.generateAddress(from: publicKey)
            try keyStorage.storePrivateKey(key: privateKey, with: address)
            return self.init(address: address, keyStorage: keyStorage)
        } catch {
            throw EthereumAccountError.importAccountError
        }
    }

    public func sign(data: Data) throws -> Data {
        let privateKeyData = try keyStorage.loadPrivateKey(for: address)
        try validate(address: address, withPrivateKey: privateKeyData)
        return try KeyUtil.sign(message: data, with: privateKeyData, hashing: true)
    }

    public func sign(hex: String) throws -> Data {
        guard let data = Data(hex: hex) else { throw EthereumAccountError.signError }
        let privateKeyData = try keyStorage.loadPrivateKey(for: address)
        try validate(address: address, withPrivateKey: privateKeyData)
        return try KeyUtil.sign(message: data, with: privateKeyData, hashing: true)
    }

    public func sign(hash: String) throws -> Data {
        guard let data = hash.web3.hexData else { throw EthereumAccountError.signError }
        let privateKeyData = try keyStorage.loadPrivateKey(for: address)
        try validate(address: address, withPrivateKey: privateKeyData)
        return try KeyUtil.sign(message: data, with: privateKeyData, hashing: false)
    }

    public func sign(message: Data) throws -> Data {
        let privateKeyData = try keyStorage.loadPrivateKey(for: address)
        try validate(address: address, withPrivateKey: privateKeyData)
        return try KeyUtil.sign(message: message, with: privateKeyData, hashing: false)
    }

    public func sign(message: String) throws -> Data {
        guard let data = message.data(using: .utf8) else { throw EthereumAccountError.signError }
        let privateKeyData = try keyStorage.loadPrivateKey(for: address)
        try validate(address: address, withPrivateKey: privateKeyData)
        return try KeyUtil.sign(message: data, with: privateKeyData, hashing: true)
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

    private func validate(address: EthereumAddress, withPrivateKey key: Data) throws {
        let retrievedAddress = try KeyUtil.generateAddress(from: KeyUtil.generatePublicKey(from: key))
        guard address == retrievedAddress else { throw EthereumAccountError.addressesDoesNotMatch }
    }
}
