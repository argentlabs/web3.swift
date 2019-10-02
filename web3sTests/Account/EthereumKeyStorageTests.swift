//
//  EthereumKeyStorageTests.swift
//  web3sTests
//
//  Created by Matt Marshall on 13/03/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import XCTest
@testable import web3swift

class EthereumKeyStorageTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testStoreLocalPrivateKey() {
        let randomData = Data.randomOfLength(256)!
        let keyStorage = EthereumKeyLocalStorage()
        
        do {
            try keyStorage.storePrivateKey(key: randomData)
        } catch {
            XCTFail("Failed to save private key. Ensure key is valid in TestConfig.swift")
        }
    }
    
    func testStoreAndLoadLocalPrivateKey() {
        let randomData = Data.randomOfLength(256)!
        let keyStorage = EthereumKeyLocalStorage()
        
        do {
            try keyStorage.storePrivateKey(key: randomData)
            let storedData = try keyStorage.loadPrivateKey()
            XCTAssertEqual(randomData, storedData)
        } catch {
            XCTFail("Failed to save private key. Ensure key is valid in TestConfig.swift")
        }
    }

}
