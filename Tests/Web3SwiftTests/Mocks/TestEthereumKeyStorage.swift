//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation
@testable import web3

class TestEthereumKeyStorage: EthereumSingleKeyStorageProtocol {
    
    private var privateKey: String

    init(privateKey: String) {
        self.privateKey = privateKey
    }

    func storePrivateKey(key: Data) throws {
    }

    func loadPrivateKey() throws -> Data {
        return privateKey.web3.hexData!
    }
}

class TestEthereumMultipleKeyStorage: EthereumMultipleKeyStorageProtocol {
    
    private var privateKey: String
    
    init(privateKey: String) {
        self.privateKey = privateKey
    }
    
    func storePrivateKey(key: Data) throws -> Void {
    }

    func loadPrivateKey() throws -> Data {
        return privateKey.web3.hexData!
    }
    
    func fetchAccounts() throws -> [EthereumAddress] {
        return []
    }

    func storePrivateKey(key: Data, with address: EthereumAddress) throws -> Void {
    }

    func loadPrivateKey(for address: EthereumAddress) throws -> Data {
        return privateKey.web3.hexData!
    }

    func deletePrivateKey(for address: EthereumAddress) throws {
    }

    func deleteAllKeys() throws {
    }
}
