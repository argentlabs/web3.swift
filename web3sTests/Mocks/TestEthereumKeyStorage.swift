//
//  TestEthereumKeyStorage.swift
//  web3sTests
//
//  Created by Matt Marshall on 14/03/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation
@testable import web3swift

class TestEthereumKeyStorage: EthereumKeyStorageProtocol {
    private var privateKey: String
    
    init(privateKey: String) {
        self.privateKey = privateKey
    }
    
    func storePrivateKey(key: Data) throws -> Void {
    }
    
    func loadPrivateKey() throws -> Data {
        return privateKey.hexData!
    }
}
