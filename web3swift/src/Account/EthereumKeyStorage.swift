//
//  EthereumKeyStorage.swift
//  web3swift
//
//  Created by Matt Marshall on 06/03/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation

public protocol EthereumKeyStorageProtocol {
    func storePrivateKey(key: Data, with address: String) throws -> Void
    func loadPrivateKey(for address: String) throws -> Data
}

public enum EthereumKeyStorageError: Error {
    case notFound
    case failedToSave
    case failedToLoad
}

public class EthereumKeyLocalStorage: EthereumKeyStorageProtocol {
    public init() {}
    
    private var address: String?
    
    private var localPath: String? {
        guard let address = address else { return nil }
        if let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            return url.appendingPathComponent(address).path
        }
        return nil
    }
    
    public func storePrivateKey(key: Data, with address: String) throws -> Void {
        self.address = address
        
        defer {
            self.address = nil
        }
        
        guard let localPath = self.localPath else {
            throw EthereumKeyStorageError.failedToSave
        }
        
        let success = NSKeyedArchiver.archiveRootObject(key, toFile: localPath)
        
        if !success {
            throw EthereumKeyStorageError.failedToSave
        }
    }
    
    public func loadPrivateKey(for address: String) throws -> Data {
        self.address = address
        
        defer {
            self.address = nil
        }
        
        guard let localPath = self.localPath else {
            throw EthereumKeyStorageError.failedToLoad
        }
        
        guard let data = NSKeyedUnarchiver.unarchiveObject(withFile: localPath) as? Data else {
            throw EthereumKeyStorageError.failedToLoad
        }

        return data
    }
}
