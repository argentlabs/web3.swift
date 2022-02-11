//
//  ERC20.swift
//  web3swift
//
//  Created by Matt Marshall on 13/04/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation
import BigInt

public protocol ERC20Protocol {
    init(client: EthereumClient)
    func name(tokenContract: EthereumAddress, completion: @escaping((Error?, String?) -> Void))
    func symbol(tokenContract: EthereumAddress, completion: @escaping((Error?, String?) -> Void))
    func decimals(tokenContract: EthereumAddress, completion: @escaping((Error?, UInt8?) -> Void))
    func balanceOf(tokenContract: EthereumAddress, address: EthereumAddress, completion: @escaping((Error?, BigUInt?) -> Void))
    func allowance(tokenContract: EthereumAddress, address: EthereumAddress, spender: EthereumAddress, completion: @escaping((Error?, BigUInt?) -> Void))
    func transferEventsTo(recipient: EthereumAddress, fromBlock: EthereumBlock, toBlock: EthereumBlock, completion: @escaping((Error?, [ERC20Events.Transfer]?) -> Void))
    func transferEventsFrom(sender: EthereumAddress, fromBlock: EthereumBlock, toBlock: EthereumBlock, completion: @escaping((Error?, [ERC20Events.Transfer]?) -> Void))

#if compiler(>=5.5) && canImport(_Concurrency)
    @available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
    func name(tokenContract: EthereumAddress) async throws -> String

    @available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
    func symbol(tokenContract: EthereumAddress) async throws -> String

    @available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
    func decimals(tokenContract: EthereumAddress) async throws -> UInt8

    @available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
    func balanceOf(tokenContract: EthereumAddress, address: EthereumAddress) async throws -> BigUInt

    @available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
    func allowance(tokenContract: EthereumAddress, address: EthereumAddress, spender: EthereumAddress) async throws -> BigUInt

    @available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
    func transferEventsTo(recipient: EthereumAddress, fromBlock: EthereumBlock, toBlock: EthereumBlock) async throws -> [ERC20Events.Transfer]

    @available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
    func transferEventsFrom(sender: EthereumAddress, fromBlock: EthereumBlock, toBlock: EthereumBlock) async throws -> [ERC20Events.Transfer]
#endif
}

public class ERC20: ERC20Protocol {
    let client: EthereumClient

    required public init(client: EthereumClient) {
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

    public func decimals(tokenContract: EthereumAddress, completion: @escaping((Error?, UInt8?) -> Void)) {
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

    public func allowance(tokenContract: EthereumAddress, address: EthereumAddress, spender: EthereumAddress, completion: @escaping((Error?, BigUInt?) -> Void)) {
        let function = ERC20Functions.allowance(contract: tokenContract, owner: address, spender: spender)
        function.call(withClient: self.client, responseType: ERC20Responses.balanceResponse.self) { (error, balanceResponse) in
            return completion(error, balanceResponse?.value)
        }
    }

    public func transferEventsTo(recipient: EthereumAddress, fromBlock: EthereumBlock, toBlock: EthereumBlock, completion: @escaping((Error?, [ERC20Events.Transfer]?) -> Void)) {

        guard let result = try? ABIEncoder.encode(recipient).bytes, let sig = try? ERC20Events.Transfer.signature() else {
            completion(EthereumSignerError.unknownError, nil)
            return
        }

        self.client.getEvents(addresses: nil,
                              topics: [ sig, nil, String(hexFromBytes: result)],
                              fromBlock: fromBlock,
                              toBlock: toBlock,
                              eventTypes: [ERC20Events.Transfer.self]) { (error, events, unprocessedLogs) in

            if let events = events as? [ERC20Events.Transfer] {
                return completion(error, events)
            } else {
                return completion(error ?? EthereumClientError.decodeIssue, nil)
            }

        }
    }

    public func transferEventsFrom(sender: EthereumAddress, fromBlock: EthereumBlock, toBlock: EthereumBlock, completion: @escaping((Error?, [ERC20Events.Transfer]?) -> Void)) {

        guard let result = try? ABIEncoder.encode(sender).bytes, let sig = try? ERC20Events.Transfer.signature() else {
            completion(EthereumSignerError.unknownError, nil)
            return
        }

        self.client.getEvents(addresses: nil,
                              topics: [ sig, String(hexFromBytes: result), nil ],
                              fromBlock: fromBlock,
                              toBlock: toBlock,
                              eventTypes: [ERC20Events.Transfer.self]) { (error, events, unprocessedLogs) in

            if let events = events as? [ERC20Events.Transfer] {
                return completion(error, events)
            } else {
                return completion(error ?? EthereumClientError.decodeIssue, nil)
            }

        }
    }
}

#if compiler(>=5.5) && canImport(_Concurrency)

@available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
extension ERC20 {
    public func name(tokenContract: EthereumAddress) async throws -> String {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            name(tokenContract: tokenContract) { error, name in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let name = name {
                    continuation.resume(returning: name)
                }
            }
        }
    }

    public func symbol(tokenContract: EthereumAddress) async throws -> String {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            symbol(tokenContract: tokenContract) { error, symbol in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let symbol = symbol {
                    continuation.resume(returning: symbol)
                }
            }
        }
    }

    public func decimals(tokenContract: EthereumAddress) async throws -> UInt8 {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<UInt8, Error>) in
            decimals(tokenContract: tokenContract) { error, decimals in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let decimals = decimals {
                    continuation.resume(returning: decimals)
                }
            }
        }
    }

    public func balanceOf(tokenContract: EthereumAddress, address: EthereumAddress) async throws -> BigUInt {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<BigUInt, Error>) in
            balanceOf(tokenContract: tokenContract, address: address) { error, balance in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let balance = balance {
                    continuation.resume(returning: balance)
                }
            }
        }
    }

    public func allowance(tokenContract: EthereumAddress, address: EthereumAddress, spender: EthereumAddress) async throws -> BigUInt {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<BigUInt, Error>) in
            allowance(tokenContract: tokenContract, address: address, spender: spender) { error, allowance in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let allowance = allowance {
                    continuation.resume(returning: allowance)
                }
            }
        }
    }

    public func transferEventsTo(recipient: EthereumAddress, fromBlock: EthereumBlock, toBlock: EthereumBlock) async throws -> [ERC20Events.Transfer] {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[ERC20Events.Transfer], Error>) in
            transferEventsTo(recipient: recipient, fromBlock: fromBlock, toBlock: toBlock) { error, events in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let events = events {
                    continuation.resume(returning: events)
                }
            }
        }
    }

    public func transferEventsFrom(sender: EthereumAddress, fromBlock: EthereumBlock, toBlock: EthereumBlock) async throws -> [ERC20Events.Transfer] {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[ERC20Events.Transfer], Error>) in
            transferEventsFrom(sender: sender, fromBlock: fromBlock, toBlock: toBlock) { error, events in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let events = events {
                    continuation.resume(returning: events)
                }
            }
        }
    }
}
#endif
