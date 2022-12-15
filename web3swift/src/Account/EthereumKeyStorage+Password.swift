//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation

public extension EthereumSingleKeyStorageProtocol {
    func encryptAndStorePrivateKey(key: Data, keystorePassword: String) throws {
        let encodedKey = try KeystoreUtil.encode(privateKey: key, password: keystorePassword)
        let publicKey = try KeyUtil.generatePublicKey(from: key)
        let address = KeyUtil.generateAddress(from: publicKey)
        try storePrivateKey(key: encodedKey, with: address)
    }

    func loadAndDecryptPrivateKey(for address: EthereumAddress, keystorePassword: String) throws -> Data {
        let encryptedKey = try loadPrivateKey(for: address)
        return try KeystoreUtil.decode(data: encryptedKey, password: keystorePassword)
    }
}
