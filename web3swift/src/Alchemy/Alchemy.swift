//
//  File.swift
//  File
//
//  Created by Ronald Mannak on 8/25/21.
//

import Foundation
import BigInt

// Or move to file ERC20+Alchemy.swift?
// https://dashboard.alchemyapi.io/composer
extension ERC20 {
    
    public func alchemy_TokenAllowance() async throws -> Data {
        return Data()
    }
    
    public func alchemy_assetTransfers() async throws -> Data {
        return Data()
    }
    
    public func alchemy_tokenBalances() async throws -> Data {
        return Data()
    }
    
    public func alchemy_tokenMetadata() async throws -> Data {
        return Data()
    }
}

// EIP 1559 related methods
extension EthereumClient {
    
//    public func feeHistory(blockRange, startingBlock, percentiles[]) async throws -> BigUInt
    
    
    /// Returns a quick estimate for maxPriorityFeePerGas in EIP 1559 transactions. Rather than using feeHistory and making a calculation yourself you can just use this method to get a quick estimate. Note: this is a geth-only method, but Alchemy handles that for you behind the scenes.
    /// # Reference
    /// [Alchemy documentation](https://docs.alchemy.com/alchemy/documentation/alchemy-web3/enhanced-web3-api#web-3-eth-getmaxpriorityfeepergas)
    /// - SeeAlso:
    /// [Alchemy documentation](https://docs.alchemy.com/alchemy/documentation/alchemy-web3/enhanced-web3-api#web-3-eth-getmaxpriorityfeepergas)
    /// - Returns: A BigUInt, which is the maxPriorityFeePerGas suggestion. You can plug this directly into your transaction field.
    public func maxPriorityFeePerGas() async throws -> BigUInt {
                
        guard let gasHex = try await EthereumRPC.execute(session: session, url: url, method: "eth_maxPriorityFeePerGas", params: [Bool](), receive: String.self) as? String,
              let gas = BigUInt(hex: gasHex) else {
            throw Web3Error.unexpectedReturnValue
        }
        return gas
    }
}

