//
//  web3.swift
//  Copyright © Argent Labs Limited. All rights reserved.
//

import Foundation

public protocol EthereumSingleKeyStorageProtocol: Sendable {
    func storePrivateKey(key: Data) throws
    func loadPrivateKey() throws -> Data
}

public protocol EthereumMultipleKeyStorageProtocol: Sendable {
    func deleteAllKeys() throws
    func deletePrivateKey(for address: EthereumAddress) throws
    func fetchAccounts() throws -> [EthereumAddress]
    func loadPrivateKey(for address: EthereumAddress) throws -> Data
    func storePrivateKey(key: Data, with address: EthereumAddress) throws
}

public enum EthereumKeyStorageError: Sendable, Error {
    case notFound
    case failedToSave
    case failedToLoad
    case failedToDelete
}

public class EthereumKeyLocalStorage: EthereumSingleKeyStorageProtocol, @unchecked Sendable {
    public init() {}

    private let address: ThreadSafeBox<EthereumAddress?> = ThreadSafeBox(nil)
    private let localFileName = "ethereumkey"

    private var addressURL: URL? {
        guard let address = address.value else {
            return nil
        }
        return folderPath?.appendingPathComponent(address.asString())
    }

    private var folderPath: URL? {
        if let url = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            return url
        }
        return nil
    }

    private var localURL: URL? {
        folderPath?.appendingPathComponent(localFileName)
    }

    private let fileManager = FileManager.default

    /// Writes the archive `NSKeyedArchiver.archiveRootObject(_:toFile:)` used to write.
    ///
    /// `requiringSecureCoding: false` is what keeps the on-disk format unchanged, so key files
    /// written by earlier versions still load.
    fileprivate func archive(_ key: Data, to url: URL) throws {
        do {
            let archived = try NSKeyedArchiver.archivedData(withRootObject: key, requiringSecureCoding: false)
            try archived.write(to: url)
        } catch {
            throw EthereumKeyStorageError.failedToSave
        }
    }

    fileprivate func unarchive(from url: URL) throws -> Data {
        do {
            let archived = try Data(contentsOf: url)
            guard let key = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSData.self, from: archived) else {
                throw EthereumKeyStorageError.failedToLoad
            }
            return key as Data
        } catch {
            throw EthereumKeyStorageError.failedToLoad
        }
    }

    public func storePrivateKey(key: Data) throws {
        guard let localURL else {
            throw EthereumKeyStorageError.failedToSave
        }

        try archive(key, to: localURL)
    }

    public func loadPrivateKey() throws -> Data {
        guard let localURL else {
            throw EthereumKeyStorageError.failedToLoad
        }

        return try unarchive(from: localURL)
    }
}

extension EthereumKeyLocalStorage: EthereumMultipleKeyStorageProtocol {
    public func fetchAccounts() throws -> [EthereumAddress] {
        guard let folderPath else {
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

    public func storePrivateKey(key: Data, with address: EthereumAddress) throws {
        self.address.withLock {
            $0 = address
        }

        defer {
            self.address.withLock {
                $0 = nil
            }
        }

        guard let addressURL = self.addressURL else {
            throw EthereumKeyStorageError.failedToSave
        }

        try archive(key, to: addressURL)
    }

    public func loadPrivateKey(for address: EthereumAddress) throws -> Data {
        self.address.withLock {
            $0 = address
        }

        defer {
            self.address.withLock {
                $0 = nil
            }
        }

        guard let addressURL = self.addressURL else {
            throw EthereumKeyStorageError.failedToLoad
        }

        return try unarchive(from: addressURL)
    }

    public func deleteAllKeys() throws {
        do {
            if let folderPath {
                let directoryContents = try fileManager.contentsOfDirectory(atPath: folderPath.path)
                let addresses = directoryContents.filter({ $0.web3.isAddress || $0 == localFileName })
                for address in addresses {
                    try deletePrivateKey(for: EthereumAddress(address))
                }
            }
        } catch {
            print("Could not delete addresses: \(error)")
            throw EthereumKeyStorageError.failedToDelete
        }
    }

    public func deletePrivateKey(for address: EthereumAddress) throws {
        do {
            if let folderPath {
                let filePathName = folderPath.appendingPathComponent(address.asString())
                try fileManager.removeItem(at: filePathName)
            }
        } catch {
            print("Could not delete address \(address): \(error)")
            throw EthereumKeyStorageError.failedToDelete
        }
    }
}
