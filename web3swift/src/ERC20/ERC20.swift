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

    func name(tokenContract: EthereumAddress, completionHandler: @escaping(Result<String, Error>) -> Void)
    func symbol(tokenContract: EthereumAddress, completionHandler: @escaping(Result<String, Error>) -> Void)
    func decimals(tokenContract: EthereumAddress, completionHandler: @escaping(Result<UInt8, Error>) -> Void)
    func balanceOf(tokenContract: EthereumAddress, address: EthereumAddress, completionHandler: @escaping(Result<BigUInt, Error>) -> Void)
    func allowance(tokenContract: EthereumAddress, address: EthereumAddress, spender: EthereumAddress, completionHandler: @escaping(Result<BigUInt, Error>) -> Void)
    func transferEventsTo(recipient: EthereumAddress, fromBlock: EthereumBlock, toBlock: EthereumBlock, completionHandler: @escaping(Result<[ERC20Events.Transfer], Error>) -> Void)
    func transferEventsFrom(sender: EthereumAddress, fromBlock: EthereumBlock, toBlock: EthereumBlock, completionHandler: @escaping(Result<[ERC20Events.Transfer], Error>) -> Void)

    // async
    func name(tokenContract: EthereumAddress) async throws -> String
    func symbol(tokenContract: EthereumAddress) async throws -> String
    func decimals(tokenContract: EthereumAddress) async throws -> UInt8
    func balanceOf(tokenContract: EthereumAddress, address: EthereumAddress) async throws -> BigUInt
    func allowance(tokenContract: EthereumAddress, address: EthereumAddress, spender: EthereumAddress) async throws -> BigUInt
    func transferEventsTo(recipient: EthereumAddress, fromBlock: EthereumBlock, toBlock: EthereumBlock) async throws -> [ERC20Events.Transfer]
    func transferEventsFrom(sender: EthereumAddress, fromBlock: EthereumBlock, toBlock: EthereumBlock) async throws -> [ERC20Events.Transfer]

    // deprecated
    func name(tokenContract: EthereumAddress, completion: @escaping((Error?, String?) -> Void))
    func symbol(tokenContract: EthereumAddress, completion: @escaping((Error?, String?) -> Void))
    func decimals(tokenContract: EthereumAddress, completion: @escaping((Error?, UInt8?) -> Void))
    func balanceOf(tokenContract: EthereumAddress, address: EthereumAddress, completion: @escaping((Error?, BigUInt?) -> Void))
    func allowance(tokenContract: EthereumAddress, address: EthereumAddress, spender: EthereumAddress, completion: @escaping((Error?, BigUInt?) -> Void))
    func transferEventsTo(recipient: EthereumAddress, fromBlock: EthereumBlock, toBlock: EthereumBlock, completion: @escaping((Error?, [ERC20Events.Transfer]?) -> Void))
    func transferEventsFrom(sender: EthereumAddress, fromBlock: EthereumBlock, toBlock: EthereumBlock, completion: @escaping((Error?, [ERC20Events.Transfer]?) -> Void))
}

public class ERC20: ERC20Protocol {
    let client: EthereumClient

    required public init(client: EthereumClient) {
        self.client = client
    }

    public func name(tokenContract: EthereumAddress, completionHandler: @escaping (Result<String, Error>) -> Void) {
        let function = ERC20Functions.name(contract: tokenContract)
        function.call(withClient: self.client, responseType: ERC20Responses.nameResponse.self) { result in
            switch result {
            case .success(let data):
                completionHandler(.success(data.value))
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }

    public func symbol(tokenContract: EthereumAddress, completionHandler: @escaping (Result<String, Error>) -> Void) {
        let function = ERC20Functions.symbol(contract: tokenContract)
        function.call(withClient: self.client, responseType: ERC20Responses.symbolResponse.self) { result in
            switch result {
            case .success(let data):
                completionHandler(.success(data.value))
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }

    public func decimals(tokenContract: EthereumAddress, completionHandler: @escaping (Result<UInt8, Error>) -> Void) {
        let function = ERC20Functions.decimals(contract: tokenContract)
        function.call(withClient: self.client,
                      responseType: ERC20Responses.decimalsResponse.self,
                      resolution: .noOffchain(failOnExecutionError: false)) { result in
            switch result {
            case .success(let data):
                completionHandler(.success(data.value))
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }

    public func balanceOf(tokenContract: EthereumAddress, address: EthereumAddress, completionHandler: @escaping (Result<BigUInt, Error>) -> Void) {
        let function = ERC20Functions.balanceOf(contract: tokenContract, account: address)
        function.call(withClient: self.client, responseType: ERC20Responses.balanceResponse.self) { result in
            switch result {
            case .success(let data):
                completionHandler(.success(data.value))
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }

    public func allowance(tokenContract: EthereumAddress, address: EthereumAddress, spender: EthereumAddress, completionHandler: @escaping (Result<BigUInt, Error>) -> Void) {
        let function = ERC20Functions.allowance(contract: tokenContract, owner: address, spender: spender)
        function.call(withClient: self.client, responseType: ERC20Responses.balanceResponse.self) { result in
            switch result {
            case .success(let data):
                completionHandler(.success(data.value))
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }

    public func transferEventsTo(recipient: EthereumAddress, fromBlock: EthereumBlock, toBlock: EthereumBlock, completionHandler: @escaping (Result<[ERC20Events.Transfer], Error>) -> Void) {
        guard let result = try? ABIEncoder.encode(recipient).bytes, let sig = try? ERC20Events.Transfer.signature() else {
            completionHandler(.failure(EthereumSignerError.unknownError))
            return
        }

        self.client.getEvents(addresses: nil,
                              topics: [ sig, nil, String(hexFromBytes: result)],
                              fromBlock: fromBlock,
                              toBlock: toBlock,
                              eventTypes: [ERC20Events.Transfer.self]) { result in
            switch result {
            case .success(let data):
                if let events = data.events as? [ERC20Events.Transfer] {
                    completionHandler(.success(events))
                } else {
                    completionHandler(.failure(EthereumClientError.decodeIssue))
                }
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }

    public func transferEventsFrom(sender: EthereumAddress, fromBlock: EthereumBlock, toBlock: EthereumBlock, completionHandler: @escaping (Result<[ERC20Events.Transfer], Error>) -> Void) {
        guard let result = try? ABIEncoder.encode(sender).bytes, let sig = try? ERC20Events.Transfer.signature() else {
            completionHandler(.failure(EthereumSignerError.unknownError))
            return
        }

        self.client.getEvents(addresses: nil,
                              topics: [ sig, String(hexFromBytes: result), nil ],
                              fromBlock: fromBlock,
                              toBlock: toBlock,
                              eventTypes: [ERC20Events.Transfer.self]) { result in

            switch result {
            case .success(let data):
                if let events = data.events as? [ERC20Events.Transfer] {
                    completionHandler(.success(events))
                } else {
                    completionHandler(.failure(EthereumClientError.decodeIssue))
                }
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }
}

// MARK: - Async/Await
extension ERC20 {
    public func name(tokenContract: EthereumAddress) async throws -> String {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            name(tokenContract: tokenContract, completionHandler: continuation.resume)
        }
    }

    public func symbol(tokenContract: EthereumAddress) async throws -> String {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            symbol(tokenContract: tokenContract, completionHandler: continuation.resume)
        }
    }

    public func decimals(tokenContract: EthereumAddress) async throws -> UInt8 {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<UInt8, Error>) in
            decimals(tokenContract: tokenContract, completionHandler: continuation.resume)
        }
    }

    public func balanceOf(tokenContract: EthereumAddress, address: EthereumAddress) async throws -> BigUInt {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<BigUInt, Error>) in
            balanceOf(tokenContract: tokenContract, address: address, completionHandler: continuation.resume)
        }
    }

    public func allowance(tokenContract: EthereumAddress, address: EthereumAddress, spender: EthereumAddress) async throws -> BigUInt {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<BigUInt, Error>) in
            allowance(tokenContract: tokenContract, address: address, spender: spender, completionHandler: continuation.resume)
        }
    }

    public func transferEventsTo(recipient: EthereumAddress, fromBlock: EthereumBlock, toBlock: EthereumBlock) async throws -> [ERC20Events.Transfer] {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[ERC20Events.Transfer], Error>) in
            transferEventsTo(recipient: recipient, fromBlock: fromBlock, toBlock: toBlock, completionHandler: continuation.resume)
        }
    }

    public func transferEventsFrom(sender: EthereumAddress, fromBlock: EthereumBlock, toBlock: EthereumBlock) async throws -> [ERC20Events.Transfer] {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[ERC20Events.Transfer], Error>) in
            transferEventsFrom(sender: sender, fromBlock: fromBlock, toBlock: toBlock, completionHandler: continuation.resume)
        }
    }
}

// MARK: - Deprecated
extension ERC20 {
    @available(*, deprecated, renamed: "name(tokenContract:completionHandler:)")
    public func name(tokenContract: EthereumAddress, completion: @escaping((Error?, String?) -> Void)) {
        name(tokenContract: tokenContract) { result in
            switch result {
            case .success(let data):
                completion(nil, data)
            case .failure(let error):
                completion(error, nil)
            }
        }
    }

    @available(*, deprecated, renamed: "symbol(tokenContract:completionHandler:)")
    public func symbol(tokenContract: EthereumAddress, completion: @escaping((Error?, String?) -> Void)) {
        symbol(tokenContract: tokenContract) { result in
            switch result {
            case .success(let data):
                completion(nil, data)
            case .failure(let error):
                completion(error, nil)
            }
        }
    }

    @available(*, deprecated, renamed: "decimals(tokenContract:completionHandler:)")
    public func decimals(tokenContract: EthereumAddress, completion: @escaping((Error?, UInt8?) -> Void)) {
        decimals(tokenContract: tokenContract) { result in
            switch result {
            case .success(let data):
                completion(nil, data)
            case .failure(let error):
                completion(error, nil)
            }
        }
    }

    @available(*, deprecated, renamed: "balanceOf(tokenContract:address:completionHandler:)")
    public func balanceOf(tokenContract: EthereumAddress, address: EthereumAddress, completion: @escaping((Error?, BigUInt?) -> Void)) {
        balanceOf(tokenContract: tokenContract, address: address) { result in
            switch result {
            case .success(let data):
                completion(nil, data)
            case .failure(let error):
                completion(error, nil)
            }
        }
    }

    @available(*, deprecated, renamed: "allowance(tokenContract:address:spender:completionHandler:)")
    public func allowance(tokenContract: EthereumAddress, address: EthereumAddress, spender: EthereumAddress, completion: @escaping((Error?, BigUInt?) -> Void)) {
        allowance(tokenContract: tokenContract, address: address, spender: spender) { result in
            switch result {
            case .success(let data):
                completion(nil, data)
            case .failure(let error):
                completion(error, nil)
            }
        }
    }

    @available(*, deprecated, renamed: "transferEventsTo(recipient:fromBlock:toBlock:completionHandler:)")
    public func transferEventsTo(recipient: EthereumAddress, fromBlock: EthereumBlock, toBlock: EthereumBlock, completion: @escaping((Error?, [ERC20Events.Transfer]?) -> Void)) {
        transferEventsTo(recipient: recipient, fromBlock: fromBlock, toBlock: toBlock) { result in
            switch result {
            case .success(let data):
                completion(nil, data)
            case .failure(let error):
                completion(error, nil)
            }
        }
    }

    @available(*, deprecated, renamed: "transferEventsFrom(sender:fromBlock:toBlock:completionHandler:)")
    public func transferEventsFrom(sender: EthereumAddress, fromBlock: EthereumBlock, toBlock: EthereumBlock, completion: @escaping((Error?, [ERC20Events.Transfer]?) -> Void)) {
        transferEventsFrom(sender: sender, fromBlock: fromBlock, toBlock: toBlock) { result in
            switch result {
            case .success(let data):
                completion(nil, data)
            case .failure(let error):
                completion(error, nil)
            }
        }
    }
}
