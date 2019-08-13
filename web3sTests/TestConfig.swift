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
    static let privateKey = "0xdeadbeef"
    
    // This is the expected public key (address) from the above private key
    static let publicKey = "0xdeadbeef"
    
    // A test ERC20 token contract (BOKKY)
    static let erc20Contract = "0x583cbBb8a8443B38aBcC0c956beCe47340ea1367"
    
    // A test ERC721 token contract (GAT)
    static let erc721Contract = "0x6F2443D87F0F6Cb6aa47b0C6a310468163871E94"
    
    // ERC165 compliant contract
    static let erc165Contract = "0x5c007a1d8051dfda60b3692008b9e10731b67fde"
}
