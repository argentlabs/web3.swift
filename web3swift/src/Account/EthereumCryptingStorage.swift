//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation

public class EthereumCryptingStorage<Wrapped>: EthereumKeyStorageProtocol where Wrapped: EthereumKeyStorageProtocol {

    private let backingStorage: Wrapped
    private var password: String?

    public init(backingStorage: Wrapped) {
        self.backingStorage = backingStorage
    }

    public func setOneTimePassword(_ password: String) {
        self.password = password
    }

    public func storePrivateKey(key: Data, with address: EthereumAddress) throws {
        guard let password else { throw StorageError.unableToGetDataBecauseOfPasswordNotFound }
        defer { self.password = nil }
        try backingStorage.encryptAndStorePrivateKey(key: key, keystorePassword: password)
    }

    public func loadPrivateKey(for address: EthereumAddress) throws -> Data {
        guard let password else { throw StorageError.unableToGetDataBecauseOfPasswordNotFound }
        defer { self.password = nil }
        return try backingStorage.loadAndDecryptPrivateKey(for: address, keystorePassword: password)
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
