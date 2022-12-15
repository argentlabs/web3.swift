//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation
import web3

class EthereumKeyStorageSpy: EthereumKeyStorageProtocol {

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
}
