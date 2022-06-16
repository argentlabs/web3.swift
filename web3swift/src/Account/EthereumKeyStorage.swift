//
//  EthereumKeyStorage.swift
//  web3swift
//
//  Created by Matt Marshall on 06/03/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation

public protocol EthereumKeyStorageProtocol {
    func fetchStoredAddresses() throws -> [String]
    func storePrivateKey(key: Data, with address: String) throws -> Void
    func deletePrivateKey(for address: String) throws -> Void
    func loadPrivateKey(for address: String) throws -> Data
}

public enum EthereumKeyStorageError: Error {
    case notFound
    case failedToSave
    case failedToLoad
    case failedToDelete
}

public class EthereumKeyLocalStorage: EthereumKeyStorageProtocol {
    public init() {}
    
    private var address: String?
    
    private var addressPath: String? {
        guard let address = address else { return nil }
        if let url = folderPath {
            return url.appendingPathComponent(address).path
        }
        return nil
    }
    
    private var folderPath: URL? {
        if let url = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            return url
        }
        return nil
    }
    
    private let fileManager = FileManager.default
    
    public func fetchStoredAddresses() throws -> [String] {
        guard let folderPath = folderPath else {
            throw EthereumKeyStorageError.failedToLoad
        }
        
        do {
            try fileManager.createDirectory(atPath: folderPath.relativePath, withIntermediateDirectories: true)
            let directoryContents = try fileManager.contentsOfDirectory(at: folderPath, includingPropertiesForKeys: nil, options: [.skipsSubdirectoryDescendants])
            
            let files = directoryContents.filter { !$0.hasDirectoryPath}.map { $0.lastPathComponent }.filter { $0.web3.isAddress }
            return (files)
        } catch {
            print(error.localizedDescription)
            throw EthereumKeyStorageError.failedToLoad
        }
    }
    
    public func storePrivateKey(key: Data, with address: String) throws -> Void {
        self.address = address
        
        defer {
            self.address = nil
        }
        
        guard let localPath = self.addressPath else {
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
        
        guard let localPath = self.addressPath else {
            throw EthereumKeyStorageError.failedToLoad
        }
        
        guard let data = NSKeyedUnarchiver.unarchiveObject(withFile: localPath) as? Data else {
            throw EthereumKeyStorageError.failedToLoad
        }
        
        return data
    }
    
    public func deletePrivateKey(for address: String) throws {
        do {
            if let folderPath = folderPath {
                let filePathName = folderPath.appendingPathComponent(address)
                try fileManager.removeItem(at: filePathName)
            }
        } catch {
            print("Could not delete address: \(error)")
            throw EthereumKeyStorageError.failedToDelete
        }
    }
}
