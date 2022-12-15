//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation

public class EthereumCryptingStorage<Wrapped>: EthereumKeyStorageProtocol where Wrapped: EthereumKeyStorageProtocol {

    public typealias PasswordProvider = () -> String

    private let backingStorage: Wrapped
    private var passwordProvider: PasswordProvider

    public init(backingStorage: Wrapped, passwordProvider: @escaping PasswordProvider) {
        self.backingStorage = backingStorage
        self.passwordProvider = passwordProvider
    }

    public func storePrivateKey(key: Data, with address: EthereumAddress) throws {
        try backingStorage.encryptAndStorePrivateKey(key: key, keystorePassword: passwordProvider())
    }

    public func loadPrivateKey(for address: EthereumAddress) throws -> Data {
        try backingStorage.loadAndDecryptPrivateKey(for: address, keystorePassword: passwordProvider())
    }
}

extension EthereumCryptingStorage: EthereumMultipleKeyStorageProtocol where Wrapped: EthereumMultipleKeyStorageProtocol {
    public func deleteAllKeys() throws {
        try backingStorage.deleteAllKeys()
    }

    public func deletePrivateKey(for address: EthereumAddress) throws {
        try backingStorage.deletePrivateKey(for: address)
    }

    public func fetchAccounts() throws -> [EthereumAddress] {
        try backingStorage.fetchAccounts()
    }
}

extension EthereumCryptingStorage {

    public enum StorageError: Error {
        case unableToGetDataBecauseOfPasswordNotFound
    }
}
