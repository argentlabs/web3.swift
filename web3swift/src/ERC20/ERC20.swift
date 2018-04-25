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
        
    public func name(tokenContract: EthereumAddress, completion: @escaping((Error?, String?) -> Void)) {
        let function = ERC20Functions.name(contract: tokenContract)
        function.call(withClient: self.client, responseType: ERC20Responses.nameResponse.self) { (error, nameResponse) in
            return completion(error, nameResponse?.value)
        }
    }
    
    public func symbol(tokenContract: EthereumAddress, completion: @escaping((Error?, String?) -> Void)) {
        let function = ERC20Functions.symbol(contract: tokenContract)
        function.call(withClient: self.client, responseType: ERC20Responses.symbolResponse.self) { (error, symbolResponse) in
            return completion(error, symbolResponse?.value)
        }
    }
    
    public func decimals(tokenContract: EthereumAddress, completion: @escaping((Error?, BigUInt?) -> Void)) {
        let function = ERC20Functions.decimals(contract: tokenContract)
        function.call(withClient: self.client, responseType: ERC20Responses.decimalsResponse.self) { (error, decimalsResponse) in
            return completion(error, decimalsResponse?.value)
        }
    }
    
    public func balanceOf(tokenContract: EthereumAddress, address: EthereumAddress, completion: @escaping((Error?, BigUInt?) -> Void)) {
        let function = ERC20Functions.balanceOf(contract: tokenContract, account: address)
        function.call(withClient: self.client, responseType: ERC20Responses.balanceResponse.self) { (error, balanceResponse) in
            return completion(error, balanceResponse?.value)
        }
    }
    
    public func transferEventsTo(recipient: EthereumAddress, fromBlock: EthereumBlock, toBlock: EthereumBlock, completion: @escaping((Error?, [ERC20Events.Transfer]?) -> Void)) {
        
        guard let addressType = ABIRawType(type: EthereumAddress.self), let result = try? ABIEncoder.encode(recipient.value, forType: addressType), let sig = try? ERC20Events.Transfer.signature() else {
            completion(EthereumSignerError.unknownError, nil)
            return
        }
        
        self.client.getEvents(addresses: nil, topics: [ sig, String(hexFromBytes: result)], fromBlock: fromBlock, toBlock: toBlock, eventTypes: [ERC20Events.Transfer.self]) { (error, events, unprocessedLogs) in
            
            if let events = events as? [ERC20Events.Transfer] {
                return completion(error, events)
            } else {
                return completion(error ?? EthereumClientError.decodeIssue, nil)
            }
            
        }
    }
}
