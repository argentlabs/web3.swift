//
//  TestEthereumKeyStorage.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

@testable import web3
import Foundation

class TestEthereumKeyStorage: EthereumSingleKeyStorageProtocol {
    private var privateKey: String

    init(privateKey: String) {
        self.privateKey = privateKey
    }

    func storePrivateKey(key: Data) throws {}

    func loadPrivateKey() throws -> Data {
        privateKey.web3.hexData!
    }
}

class TestEthereumMultipleKeyStorage: EthereumMultipleKeyStorageProtocol {
    private var privateKey: String

    init(privateKey: String) {
        self.privateKey = privateKey
    }

    func storePrivateKey(key: Data) throws {}

    func loadPrivateKey() throws -> Data {
        privateKey.web3.hexData!
    }

    func fetchAccounts() throws -> [EthereumAddress] {
        []
    }

    func storePrivateKey(key: Data, with address: EthereumAddress) throws {}

    func loadPrivateKey(for address: EthereumAddress) throws -> Data {
        privateKey.web3.hexData!
    }

    func deletePrivateKey(for address: EthereumAddress) throws {}

    func deleteAllKeys() throws {}
}
