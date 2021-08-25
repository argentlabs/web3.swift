//
//  ERC20.swift
//  web3swift
//
//  Created by Matt Marshall on 13/04/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation
import BigInt

public class ERC20 {
    let client: EthereumClient
    
    public init(client: EthereumClient) {
        self.client = client
    }
        
    @available(*, deprecated, message: "Prefer async alternative instead")
    public func name(tokenContract: EthereumAddress,
                     completion: @escaping((Error?, String?) -> Void)) {
        async {
            do {
                let result = try await name(tokenContract: tokenContract)
                completion(nil, result)
            } catch {
                completion(error, nil)
            }
        }
    }
    
    public func name(tokenContract: EthereumAddress) async throws -> String {
        let function = ERC20Functions.name(contract: tokenContract)
        let nameResponse = try await function.call(withClient: self.client, responseType: ERC20Responses.nameResponse.self)
        return nameResponse.value
    }
    
    @available(*, deprecated, message: "Prefer async alternative instead")
    public func symbol(tokenContract: EthereumAddress,
                       completion: @escaping((Error?, String?) -> Void)) {
        async {
            do {
                let result = try await symbol(tokenContract: tokenContract)
                completion(nil, result)
            } catch {
                completion(error, nil)
            }
        }
    }
    
    public func symbol(tokenContract: EthereumAddress) async throws -> String {
        let function = ERC20Functions.symbol(contract: tokenContract)
        let symbolResponse = try await function.call(withClient: self.client, responseType: ERC20Responses.symbolResponse.self)
        return symbolResponse.value
    }
    
    @available(*, deprecated, message: "Prefer async alternative instead")
    public func decimals(tokenContract: EthereumAddress,
                         completion: @escaping((Error?, UInt8?) -> Void)) {
        async {
            do {
                let result = try await decimals(tokenContract: tokenContract)
                completion(nil, result)
            } catch {
                completion(error, nil)
            }
        }
    }
    
    public func decimals(tokenContract: EthereumAddress) async throws -> UInt8? {
        let function = ERC20Functions.decimals(contract: tokenContract)
        let decimalsResponse = try await function.call(withClient: self.client, responseType: ERC20Responses.decimalsResponse.self)
        return decimalsResponse.value
    }
    
    @available(*, deprecated, message: "Prefer async alternative instead")
    public func balanceOf(tokenContract: EthereumAddress,
                          address: EthereumAddress,
                          completion: @escaping((Error?, BigUInt?) -> Void)) {
        async {
            do {
                let result = try await balanceOf(tokenContract: tokenContract, address: address)
                completion(nil, result)
            } catch {
                completion(error, nil)
            }
        }
    }
    
    public func balanceOf(tokenContract: EthereumAddress,
                          address: EthereumAddress) async throws -> BigUInt {
        let function = ERC20Functions.balanceOf(contract: tokenContract, account: address)
        let balanceResponse = try await function.call(withClient: self.client, responseType: ERC20Responses.balanceResponse.self)
        return balanceResponse.value
    }
    
    @available(*, deprecated, message: "Prefer async alternative instead")
    public func allowance(tokenContract: EthereumAddress,
                          address: EthereumAddress,
                          spender: EthereumAddress,
                          completion: @escaping((Error?, BigUInt?) -> Void)) {
        async {
            do {
                let result = try await allowance(tokenContract: tokenContract, address: address, spender: spender)
                completion(nil, result)
            } catch {
                completion(error, nil)
            }
        }
    }
    
    public func allowance(tokenContract: EthereumAddress,
                          address: EthereumAddress,
                          spender: EthereumAddress) async throws -> BigUInt {
        let function = ERC20Functions.allowance(contract: tokenContract, owner: address, spender: spender)
        let balanceResponse = try await function.call(withClient: self.client, responseType: ERC20Responses.balanceResponse.self)
        return balanceResponse.value
    }
    
    @available(*, deprecated, message: "Prefer async alternative instead")
    public func transferEventsTo(recipient: EthereumAddress,
                                 fromBlock: EthereumBlock,
                                 toBlock: EthereumBlock,
                                 completion: @escaping((Error?, [ERC20Events.Transfer]?) -> Void)) {
        async {
            do {
                let result = try await transferEventsTo(recipient: recipient, fromBlock: fromBlock, toBlock: toBlock)
                completion(nil, result)
            } catch {
                completion(error, nil)
            }
        }
    }
    
    
    public func transferEventsTo(recipient: EthereumAddress,
                                 fromBlock: EthereumBlock = .earliest,
                                 toBlock: EthereumBlock = .latest) async throws -> [ERC20Events.Transfer] {
        
        let result = try ABIEncoder.encode(recipient).bytes
        let sig = try ERC20Events.Transfer.signature()
                
        let (events, _) = try await self.client.getEvents(addresses: nil, topics: [ sig, nil, String(hexFromBytes: result)], fromBlock: fromBlock, toBlock: toBlock, eventTypes: [ERC20Events.Transfer.self])
        guard let events = events as? [ERC20Events.Transfer] else {
            throw Web3Error.decodeIssue
        }
        return events
    }
    
    @available(*, deprecated, message: "Prefer async alternative instead")
    public func transferEventsFrom(sender: EthereumAddress,
                                   fromBlock: EthereumBlock,
                                   toBlock: EthereumBlock,
                                   completion: @escaping((Error?, [ERC20Events.Transfer]?) -> Void)) {
        async {
            do {
                let result = try await transferEventsFrom(sender: sender, fromBlock: fromBlock, toBlock: toBlock)
                completion(nil, result)
            } catch {
                completion(error, nil)
            }
        }
    }    
    
    public func transferEventsFrom(sender: EthereumAddress,
                                   fromBlock: EthereumBlock = .earliest,
                                   toBlock: EthereumBlock = .latest) async throws -> [ERC20Events.Transfer] {
        
        let result = try ABIEncoder.encode(sender).bytes
        let sig = try ERC20Events.Transfer.signature()
        
        let (events, _) = try await self.client.getEvents(addresses: nil, topics: [ sig, String(hexFromBytes: result), nil ], fromBlock: fromBlock, toBlock: toBlock, eventTypes: [ERC20Events.Transfer.self])
        
        guard let events = events as? [ERC20Events.Transfer] else {
            throw Web3Error.decodeIssue
        }
        return events
    }

}
