//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation
import web3

struct TestConfig: Sendable {
    // RPC endpoints.
    //
    // Keyless public endpoints, so the suite runs on a fresh clone with no credentials and no
    // account to manage. These previously pointed at a single free-tier Infura key committed
    // here, which every contributor and every CI run drained in common — once its credits ran
    // out the whole suite failed with unrelated-looking errors.
    //
    // Two constraints on any replacement. Providers cap eth_getLogs by block range, so a
    // narrower endpoint needs `logsFromBlock`/`logsToBlock` narrowed to match. And the endpoint
    // must serve log queries that carry no address filter, since `transferEventsTo` and
    // `transferEventsFrom` search across all contracts by design — publicnode, for one, rejects
    // those with -32701 unless you pay for a dedicated node.
    static let clientUrl = "https://sepolia.gateway.tenderly.co"

    // Deliberately a different provider from `clientUrl`: it spreads the suite's request volume
    // across two free endpoints instead of exhausting one.
    static let mainnetUrl = "https://ethereum-rpc.publicnode.com"

    static let wssUrl = "wss://sepolia.gateway.tenderly.co"
    static let wssMainnetUrl = "wss://mainnet.gateway.tenderly.co"

    // An EOA with some Ether, so that we can test sending transactions (pay for gas). Set by CI
//    static let privateKey = "SET_YOUR_KEY_HERE"

    // This is the expected public key (address) from the above private key
//    static let publicKey = "SET_YOUR_PUBLIC_ADDRESS_HERE"

    // Block window used by the log and event tests.
    //
    // Providers cap eth_getLogs by block range (Infura rejects anything over 10,000 blocks), so
    // scanning `.Earliest ... .Latest` no longer works — Sepolia is past 11M blocks and a full
    // scan would need over a thousand sequential requests. These tests query a fixed historical
    // window around the fixture transactions instead. The window is in the past and immutable,
    // so the expected counts stay stable over time.
    static let logsFromBlock = EthereumBlock(rawValue: 4_885_000)
    static let logsToBlock = EthereumBlock(rawValue: 4_925_000)

    /// How many blocks the endpoint above accepts in one `eth_getLogs` call.
    ///
    /// `nil` because it serves the whole window in a single request. An endpoint with a
    /// narrower cap — Infura allows 10,000 — needs this set so queries are chunked to fit.
    static let maxBlockRange: Int? = nil

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
         static let clientURL = URL(string: "https://sepolia.era.zksync.dev")!
    }
}


@discardableResult public func with<Root>(_ root: Root, _ block: (inout Root) throws -> Void) rethrows -> Root {
    var copy = root
    try block(&copy)
    return copy
}
