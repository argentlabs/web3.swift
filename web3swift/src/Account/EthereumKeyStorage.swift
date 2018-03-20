//
//  EthereumKeyStorage.swift
//  web3swift
//
//  Created by Matt Marshall on 06/03/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation

public protocol EthereumKeyStorageProtocol {
    func storePrivateKey(key: Data) throws -> Void
    func loadPrivateKey() throws -> Data
}

public enum EthereumKeyStorageError: Error {
    case notFound
    case failedToSave
    case failedToLoad
}

public class EthereumKeyLocalStorage: EthereumKeyStorageProtocol {
    private var localPath: String? {
        if let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            return url.appendingPathComponent("EthereumKey").path
        }
        return nil
    }
    
    public func storePrivateKey(key: Data) throws -> Void {
        guard let localPath = self.localPath else {
            throw EthereumKeyStorageError.failedToSave
        }
        
        let success = NSKeyedArchiver.archiveRootObject(key, toFile: localPath)
        
        if !success {
            throw EthereumKeyStorageError.failedToSave
        }
    }
    
    public func loadPrivateKey() throws -> Data {
        guard let localPath = self.localPath else {
            throw EthereumKeyStorageError.failedToLoad
        }
        
        guard let data = NSKeyedUnarchiver.unarchiveObject(withFile: localPath) as? Data else {
            throw EthereumKeyStorageError.failedToLoad
        }

        return data
    }
}
