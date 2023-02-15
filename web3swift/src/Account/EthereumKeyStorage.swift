//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation

public protocol EthereumKeyStorageProtocol {
    func storePrivateKey(key: Data, with address: EthereumAddress) async throws
    func loadPrivateKey(for address: EthereumAddress) async throws -> Data
}

public protocol EthereumMultipleKeyStorageProtocol: EthereumKeyStorageProtocol {
    func deleteAllKeys() async throws
    func deletePrivateKey(for address: EthereumAddress) async throws
    func fetchAccounts() async throws -> [EthereumAddress]
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
    private let localFileName = "ethereumkey"

    private var addressPath: String? {
        guard let address = address else {
            return nil
        }
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

    private var localPath: String? {
        if let url = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            return url.appendingPathComponent(localFileName).path
        }
        return nil
    }

    private let fileManager = FileManager.default

    public func storePrivateKey(key: Data) async throws {
        guard let localPath = localPath else {
            throw EthereumKeyStorageError.failedToSave
        }

        let success = NSKeyedArchiver.archiveRootObject(key, toFile: localPath)

        if !success {
            throw EthereumKeyStorageError.failedToSave
        }
    }

    public func loadPrivateKey() async throws -> Data {
        guard let localPath = localPath else {
            throw EthereumKeyStorageError.failedToLoad
        }

        guard let data = NSKeyedUnarchiver.unarchiveObject(withFile: localPath) as? Data else {
            throw EthereumKeyStorageError.failedToLoad
        }

        return data
    }
}

extension EthereumKeyLocalStorage: EthereumMultipleKeyStorageProtocol {
    public func fetchAccounts() async throws -> [EthereumAddress] {
        guard let folderPath = folderPath else {
            throw EthereumKeyStorageError.failedToLoad
        }

        do {
            try fileManager.createDirectory(atPath: folderPath.relativePath, withIntermediateDirectories: true)
            let directoryContents = try fileManager.contentsOfDirectory(at: folderPath, includingPropertiesForKeys: nil, options: [.skipsSubdirectoryDescendants])

            let adressStrings = directoryContents.filter { !$0.hasDirectoryPath }.map { $0.lastPathComponent }.filter { $0.web3.isAddress }
            let ethereumAdresses = adressStrings.map { EthereumAddress($0) }
            return ethereumAdresses
        } catch {
            print(error.localizedDescription)
            throw EthereumKeyStorageError.failedToLoad
        }
    }

    public func storePrivateKey(key: Data, with address: EthereumAddress) async throws {
        self.address = address.value

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

    public func loadPrivateKey(for address: EthereumAddress) async throws -> Data {
        self.address = address.value

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

    public func deleteAllKeys() async throws {
        do {
            if let folderPath = folderPath {
                let directoryContents = try fileManager.contentsOfDirectory(atPath: folderPath.path)
                let addresses = directoryContents.filter({ $0.web3.isAddress || $0 == localFileName })
                for address in addresses {
                    try await deletePrivateKey(for: EthereumAddress(address))
                }
            }
        } catch {
            print("Could not delete addresses: \(error)")
            throw EthereumKeyStorageError.failedToDelete
        }
    }

    public func deletePrivateKey(for address: EthereumAddress) async throws {
        do {
            if let folderPath = folderPath {
                let filePathName = folderPath.appendingPathComponent(address.value)
                try fileManager.removeItem(at: filePathName)
            }
        } catch {
            print("Could not delete address \(address): \(error)")
            throw EthereumKeyStorageError.failedToDelete
        }
    }
}
