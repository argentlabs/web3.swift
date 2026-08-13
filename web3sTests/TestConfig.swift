//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation
import XCTest
import web3

/// The funded account's key, or a skip.
///
/// Call this from any test that has to spend Ether. Outside contributors and fresh clones do not
/// have the key, and a skip tells them that plainly instead of failing on something they cannot
/// fix.
func requireFundedPrivateKey() throws -> String {
    guard let key = TestConfig.fundedPrivateKey else {
        throw XCTSkip(
            """
            Skipping: this test spends Ether and needs the funded account. Export TESTS_PRIVATEKEY \
            to run it. Pull requests from forks never receive repository secrets, so it is expected \
            to skip there.
            """
        )
    }
    return key
}

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

    // A throwaway key, committed on purpose. It holds nothing on any network and never will.
    //
    // Most of what used to need "the" key only needs *a* key: deriving an address, producing a
    // deterministic signature, unlocking a fake key store. Those use this one, so the suite runs
    // on a fresh clone with no setup, and on pull requests from forks, which GitHub never gives
    // secrets to.
    //
    // This is the well-known Anvil/Hardhat account #0. It is public by design — never put
    // anything in it.
    static let signingPrivateKey = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"

    // The address `signingPrivateKey` derives to.
    static let signingPublicKey = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"

    // The address of the funded account. An address is not a secret, and the log and nonce tests
    // need this specific one because the fixtures they assert against are its on-chain history.
    static let publicKey = "0xE78e5ecb061fE3DD1672dDDA7b5116213B23B99A"

    // The key for the account above, which holds real Sepolia Ether. Supplied through the
    // environment so it never has to be written to a file: CI passes the repository secret,
    // and locally you can `export TESTS_PRIVATEKEY=0x...` if you have it.
    //
    // Nil whenever it is absent, which is the normal case for outside contributors. The handful
    // of tests that have to pay gas skip themselves rather than failing.
    static let fundedPrivateKey: String? = {
        guard let key = ProcessInfo.processInfo.environment["TESTS_PRIVATEKEY"], !key.isEmpty else {
            return nil
        }
        return key
    }()

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
