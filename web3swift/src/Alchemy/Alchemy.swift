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
        struct CallParams: Encodable {
            let contract: EthereumAddress
            let owner: EthereumAddress
            let spender: EthereumAddress
        }
        
        let params = CallParams(contract: tokenContract, owner: owner, spender: spender)
        guard let response = try await EthereumRPC.execute(session: self.session, url: self.url, method: "alchemy_getTokenAllowance", params: [params], receive: String.self) as? String, let allowance = BigUInt(response) else {
            throw Web3Error.unexpectedReturnValue
        }
        return allowance
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
    
    /// Returns an array of asset transfers based on the specified paramaters.
    /// - Parameters:
    ///   - fromBlock: in hex string or "latest". optional (default to latest)
    ///   - toBlock:  in hex string or "latest". optional (default to latest)
    ///   - fromAddress: in hex string. optional
    ///   - toAddress:  in hex string. optional.
    ///   - contractAddresses:  list of hex strings. optional.
    ///   - transferCategory: list of any combination of external, token. optional, if blank, would include both.
    ///   - excludeZeroValue:  aBoolean . optional (default true)
    ///   - maxCount: max number of results to return per call. optional (default 1000)
    ///   - pageKey: for pagination. optional
    /// - Returns: Returns an array of asset transfers based on the specified paramaters.
    public func alchemyAssetTransfers(fromBlock: EthereumBlock = EthereumBlock(rawValue: 0), toBlock: EthereumBlock = .latest, fromAddress: EthereumAddress? = nil, toAddress: EthereumAddress? = nil, contractAddresses: [EthereumAddress]? = nil, transferCategory: AlchemyAssetTransferCategory = .all, excludeZeroValue: Bool = true, maxCount: Int? = nil, pageKey: Int? = nil) async throws -> [AlchemyAssetTransfer] {
        
        enum TransferCategory: String, Encodable {
            case external = "external"
            case internalCategory = "internal"
            case token = "token"
        }
        
        struct CallParams: Encodable {
            let fromBlock: EthereumBlock? // in hex string or "latest". optional (default to latest)
            let toBlock: EthereumBlock? //in hex string or "latest". optional (default to latest)
            let fromAddress: EthereumAddress? // in hex string. optional
            let toAddress: EthereumAddress? // in hex string. optional.
            let contractAddresses: [EthereumAddress]? // list of hex strings. optional.
            let category: String? // list of any combination of external, token. optional, if blank, would include both.
            let excludeZeroValue: Bool // aBoolean . optional (default true)
            let maxCount: Int? // max number of results to return per call. optional (default 1000)
            let pageKey: Int? // for pagination. optional
        }
        
        let params = CallParams(fromBlock: fromBlock, toBlock: toBlock, fromAddress: fromAddress, toAddress: toAddress, contractAddresses: contractAddresses, category: (transferCategory == .all ? nil : transferCategory.rawValue), excludeZeroValue: excludeZeroValue, maxCount: maxCount, pageKey: pageKey)            
    
        guard let response = try await EthereumRPC.execute(session: self.session, url: self.url, method: "alchemy_getAssetTransfers", params: [params], receive: AlchemyAssetTransfers.self) as? AlchemyAssetTransfers else {
            throw Web3Error.unexpectedReturnValue
        }
        return response.transfers
    }
    


    // EIP 1559 related methods
    
    //
    
    /// Fetches the fee history for the given block range as per the (eth spec)[https://github.com/ethereum/eth1.0-specs/blob/master/json-rpc/spec.json].
    /// - SeeAlso:
    /// https://docs.alchemy.com/alchemy/documentation/alchemy-web3/enhanced-web3-api#web-3-eth-getfeehistory-blockrange-startingblock-percentiles
    /// - Parameters:
    ///   - blockRange: The number of blocks for which to fetch historical fees. Can be an integer or a hex string.
    ///   - startingBlock: The block to start the search. The result will look backwards from here. Can be a hex string or a predefined block string e.g. "latest".
    ///   - percentiles:  (Optional) An array of numbers that define which percentiles of reward values you want to see for each block.
    /// - Returns: An object with the following fields:
    /// oldestBlock: The oldest block in the range that the fee history is being returned for.
    /// baseFeePerGas: An array of base fees for each block in the range that was looked up. These are the same values that would be returned on a block for the eth_getBlockByNumber method.
    /// gasUsedRatio: An array of the ratio of gas used to gas limit for each block.
    /// reward: Only returned if a percentiles paramater was provided. Each block will have an array corresponding to the percentiles provided. Each element of the nested array will have the tip provided to miners for the percentile given. So if you provide [50, 90] as the percentiles then each block will have a 50th percentile reward and a 90th percentile reward.
    public func feeHistory(blockRange: Int, startingBlock: EthereumBlock = .latest, percentiles: [Int]) async throws -> FeeHistoryResponse {
        
        struct CallParams: Encodable {
            let blockRange: Int
            let startingBlock: EthereumBlock
            let percentiles: [Int]

            func encode(to encoder: Encoder) throws {
                var container = encoder.unkeyedContainer()
                try container.encode(blockRange)
                try container.encode(startingBlock)
                try container.encode(percentiles)
            }
        }
        
        let callParams = CallParams(blockRange: blockRange, startingBlock: startingBlock, percentiles: percentiles)        
        guard let response = try await EthereumRPC.execute(session: self.session, url: self.url, method: "eth_feeHistory", params: callParams, receive: FeeHistoryResponse.self) as? FeeHistoryResponse else {
            throw Web3Error.unexpectedReturnValue
        }
        
        return response
    }
    
    
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

