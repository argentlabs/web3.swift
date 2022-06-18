//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation

public protocol EthereumKeyStorageProtocol {
    func storePrivateKey(key: Data) throws
    func loadPrivateKey() throws -> Data
}

public enum EthereumKeyStorageError: Error {
    case notFound
    case failedToSave
    case failedToLoad
}

public class EthereumKeyLocalStorage: EthereumKeyStorageProtocol {
    public init() {}

    private var localPath: String? {
        if let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            return url.appendingPathComponent("EthereumKey").path
        }
        return nil
    }

    public func storePrivateKey(key: Data) throws {
        guard let localPath = localPath else {
            throw EthereumKeyStorageError.failedToSave
        }

        let success = NSKeyedArchiver.archiveRootObject(key, toFile: localPath)

        if !success {
            throw EthereumKeyStorageError.failedToSave
        }
    }

    public func loadPrivateKey() throws -> Data {
        guard let localPath = localPath else {
            throw EthereumKeyStorageError.failedToLoad
        }

        guard let data = NSKeyedUnarchiver.unarchiveObject(withFile: localPath) as? Data else {
            throw EthereumKeyStorageError.failedToLoad
        }

        return data
    }
}
