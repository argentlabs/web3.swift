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

extension EthereumClient {
    
    /// Returns token balances for a specific address given a list of contracts.
    /// - SeeAlso:
    ///  (TokenAllowance documentation on Alchemy)[https://docs.alchemy.com/alchemy/documentation/alchemy-web3/enhanced-web3-api#web-3-alchemy-gettokenallowance-contract-owner-spender]
    /// - Parameters:
    ///   - tokenContract: The address of the token contract.
    ///   - owner: The address of the token owner.
    ///   - spender: The address of the token spender.
    /// - Returns: The allowance amount, as a string representing a base-10 number.
    public func alchemyTokenAllowance(tokenContract: EthereumAddress,
                                       owner: EthereumAddress,
                                      spender: EthereumAddress) async throws -> BigUInt {
        let function = ERC20Functions.TokenAllowance(contract: tokenContract, owner: owner, spender: spender)
        let balanceResponse = try await function.call(withClient: self, responseType: ERC20Responses.balanceResponse.self)
        return balanceResponse.value
    }
    
    
    /// Returns token balances for a specific address given a list of contracts.
    /// - SeeAlso:
    /// (TokenBalances documentation on Alchemy)[https://docs.alchemy.com/alchemy/documentation/alchemy-web3/enhanced-web3-api#web-3-alchemy-gettokenbalances-address-contractaddresses]
    /// - Parameters:
    ///   - address: The address for which token balances will be checked.
    ///   - tokenAddresses: An array of contract addresses. if nil, a list of the top 100 DEFAULT_TOKENS will be returned
    /// - Returns: An array of AlchemyTokenBalances.
    public func alchemyTokenBalances(address: EthereumAddress, tokenAddresses: [EthereumAddress]? = nil) async throws -> [AlchemyTokenBalance] {
        
        struct CallParams: Encodable {
            let address: EthereumAddress
            let tokenAddresses: [EthereumAddress]
            
            func encode(to encoder: Encoder) throws {
                var container = encoder.unkeyedContainer()
                try container.encode(address.value)
                try container.encode(tokenAddresses.map{ $0.value })
            }
        }
        
        let response: Any
        if let tokenAddresses = tokenAddresses {
            let params = CallParams(address: address, tokenAddresses: tokenAddresses)
            response = try await EthereumRPC.execute(session: self.session, url: self.url, method: "alchemy_getTokenBalances", params: params, receive: AlchemyTokenBalances.self)
        } else {
            response = try await EthereumRPC.execute(session: self.session, url: self.url, method: "alchemy_getTokenBalances", params:  [address.value, "DEFAULT_TOKENS"], receive: AlchemyTokenBalances.self)
        }
        
        if let response = response as? AlchemyTokenBalances {
//            dump(response)
            return response.tokenBalances
        } else {
            throw Web3Error.unexpectedReturnValue
        }
    }
    
        
    /// Returns metadata (name, symbol, decimals, logo) for a given token contract address.
    /// - Parameter tokenAddresss: The address of the token contract.
    /// - Returns: An object with the following fields:
    /// name: The token's name. null if not defined in the contract and not available from other sources.
    /// symbol: The token's symbol. null if not defined in the contract and not available from other sources.
    /// decimals: The token's decimals. null if not defined in the contract and not available from other sources.
    /// logo: URL of the token's logo image. null if not available.
    public func alchemyTokenMetadata(tokenAddresss: EthereumAddress) async throws -> AlchemyTokenMetadata {
        guard let response = try await EthereumRPC.execute(session: self.session, url: self.url, method: "alchemy_getTokenMetadata", params:  [tokenAddresss.value], receive: AlchemyTokenMetadata.self) as? AlchemyTokenMetadata else {
            throw Web3Error.unexpectedReturnValue
        }
        return response
    }
        
    public func alchemyAssetTransfers() async throws -> Data {
        return Data()
    }

    // EIP 1559 related methods
    
    // https://docs.alchemy.com/alchemy/documentation/alchemy-web3/enhanced-web3-api#web-3-eth-getfeehistory-blockrange-startingblock-percentiles
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

