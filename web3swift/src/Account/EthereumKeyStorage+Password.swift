//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation

public extension EthereumKeyStorageProtocol {
    func encryptAndStorePrivateKey(key: Data, keystorePassword: String) throws {
        let encodedKey = try KeystoreUtil.encode(privateKey: key, password: keystorePassword)
        try storePrivateKey(key: encodedKey)
    }

    func loadAndDecryptPrivateKey(keystorePassword: String) throws -> Data {
        let encryptedKey = try loadPrivateKey()
        return try KeystoreUtil.decode(data: encryptedKey, password: keystorePassword)
    }
}
