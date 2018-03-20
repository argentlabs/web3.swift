//
//  TestConfig.swift
//  web3swiftTests
//
//  Created by Matt Marshall on 20/03/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation

struct TestConfig {
    // This is the proxy URL for connecting to the Blockchain. For testing we usually use the Ropsten network on Infura
    static let clientUrl = "https://ropsten.infura.io/MY_INFURA_URL"
    
    // A private key with some Ether, so that we can test sending transactions (pay for gas)
    static let privateKey = "MY_PRIVATE_KEY"
    
    // This is the expected public key (address) from the above private key
    static let publicKey = "MY_PUBLIC_KEY"
}
