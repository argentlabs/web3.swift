//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation
import web3

struct TestConfig {
    // This is the proxy URL for connecting to the Blockchain. For testing we usually use the Sepolia network on Infura. Using free tier, so might hit rate limits
    static let clientUrl = "https://sepolia.infura.io/v3/b2f4b3f635d8425c96854c3d28ba6bb0"
    static let mainnetUrl = "https://mainnet.infura.io/v3/b2f4b3f635d8425c96854c3d28ba6bb0"

    // This is the proxy wss URL for connecting to the Blockchain. For testing we usually use the Sepolia network on Infura. Using free tier, so might hit rate limits
    static let wssUrl = "wss://sepolia.infura.io/ws/v3/b2f4b3f635d8425c96854c3d28ba6bb0"
    static let wssMainnetUrl = "wss://mainnet.infura.io/ws/v3/b2f4b3f635d8425c96854c3d28ba6bb0"

    // An EOA with some Ether, so that we can test sending transactions (pay for gas). Set by CI
//    static let privateKey = "SET_YOUR_KEY_HERE"

    // This is the expected public key (address) from the above private key
//    static let publicKey = "SET_YOUR_PUBLIC_ADDRESS_HERE"

    // A test ERC20 token contract (USDC)
    static let erc20Contract = "0xF31B086459C2cdaC006Feedd9080223964a9cDdB"

    // A test ERC721 token contract (W3ST)
    static let erc721Contract = "0x09c66F8B33933823C472E932fBeB19b0762C6971"

    // ERC165 compliant contract
    static let erc165Contract = "0x85741a0a123C6BD61f327F32E633bA4c0C75A7d9"
    static let nonerc165Contrat = "0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984"

    static let webSocketConfig = WebSocketConfiguration(maxFrameSize: 1_000_000)

    static let network = EthereumNetwork.sepolia

     enum ZKSync {
         static let chainId = 280
         static let network = EthereumNetwork.custom("\(280)")
         static let clientURL = URL(string: "https://zksync2-testnet.zksync.dev")!
    }
}


@discardableResult public func with<Root>(_ root: Root, _ block: (inout Root) throws -> Void) rethrows -> Root {
    var copy = root
    try block(&copy)
    return copy
}
