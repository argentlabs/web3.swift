//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation

struct TestConfig {
    // This is the proxy URL for connecting to the Blockchain. For testing we usually use the Ropsten network on Infura. Using free tier, so might hit rate limits
    static let clientUrl = "https://ropsten.infura.io/v3/b2f4b3f635d8425c96854c3d28ba6bb0"
    
    // An EOA with some Ether, so that we can test sending transactions (pay for gas)
    static let privateKey = "0xef4e182ae2cf32192d2a62c1159c8c4f7f2d658c303d0dfca5791a205456a132"
    
    // This is the expected public key (address) from the above private key
    static let publicKey = "0x719561fee351F7aC6560D0302aE415FfBEEc0B51"
    
    // A test ERC20 token contract (BOKKY)
    static let erc20Contract = "0x583cbBb8a8443B38aBcC0c956beCe47340ea1367"
    
    // A test ERC721 token contract (GAT)
    static let erc721Contract = "0x6F2443D87F0F6Cb6aa47b0C6a310468163871E94"
    
    // ERC165 compliant contract
    static let erc165Contract = "0x5c007a1d8051dfda60b3692008b9e10731b67fde"
    
    enum ZKSync {
        static let chainId = 280
        static let clientURL = URL(string: "https://zksync2-testnet.zksync.dev")!
    }
}


@discardableResult public func with<Root>(_ root: Root, _ block: (inout Root) throws -> Void) rethrows -> Root {
    var copy = root
    try block(&copy)
    return copy
}
