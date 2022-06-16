//
//  TestEthereumKeyStorage.swift
//  web3sTests
//
//  Created by Matt Marshall on 14/03/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation
@testable import web3

class TestEthereumKeyStorage: EthereumKeyStorageProtocol {
    
    private var privateKey: String
    
    init(privateKey: String) {
        self.privateKey = privateKey
    }
    
    func fetchStoredAddresses() throws -> [String] {
        return ["first", "second"]
    }
    
    func storePrivateKey(key: Data, with address: String) throws -> Void {
    }
    
    func loadPrivateKey(for address: String) throws -> Data {
        return privateKey.web3.hexData!
    }
}
