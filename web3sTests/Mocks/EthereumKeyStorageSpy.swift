//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation
import web3

class EthereumKeyStorageSpy: EthereumMultipleKeyStorageProtocol {

    var storePrivateKeyCallsCount: Int { storePrivateKeyRecordedData.count }
    private(set) var storePrivateKeyRecordedData = [(key: Data, address: EthereumAddress)]()

    func storePrivateKey(key: Data, with address: EthereumAddress) throws {
        storePrivateKeyRecordedData.append((key, address))
    }

    var loadPrivateKeyReturnValue = Data()
    var loadPrivateKeyCallsCount: Int { loadPrivateKeyRecordedData.count }
    private(set) var loadPrivateKeyRecordedData = [EthereumAddress]()

    func loadPrivateKey(for address: EthereumAddress) throws -> Data {
        loadPrivateKeyRecordedData.append(address)
        return loadPrivateKeyReturnValue
    }

    private(set) var deleteAllKeysCallsCount = 0

    func deleteAllKeys() throws {
        deleteAllKeysCallsCount += 1
    }

    var deletePrivateKeyCallsCount: Int { deletePrivateKeyRecordedData.count }
    private(set) var deletePrivateKeyRecordedData = [EthereumAddress]()

    func deletePrivateKey(for address: EthereumAddress) throws {
        deletePrivateKeyRecordedData.append(address)
    }

    var fetchAccountsReturnValue = [EthereumAddress]()
    private(set) var fetchAccountsCallsCount = 0

    func fetchAccounts() throws -> [EthereumAddress] {
        fetchAccountsCallsCount += 1
        return fetchAccountsReturnValue
    }
}
