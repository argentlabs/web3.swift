//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import BigInt
import Foundation

public protocol ERC20Protocol {
    init(client: EthereumClientProtocol)

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
}

public class ERC20: ERC20Protocol {
    let client: EthereumClientProtocol

    required public init(client: EthereumClientProtocol) {
        self.client = client
    }

    public func name(tokenContract: EthereumAddress, completionHandler: @escaping (Result<String, Error>) -> Void) {
        let function = ERC20Functions.name(contract: tokenContract)
        function.call(withClient: client, responseType: ERC20Responses.nameResponse.self) { result in
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
        function.call(withClient: client, responseType: ERC20Responses.symbolResponse.self) { result in
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
        function.call(withClient: client,
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
        function.call(withClient: client, responseType: ERC20Responses.balanceResponse.self) { result in
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
        function.call(withClient: client, responseType: ERC20Responses.balanceResponse.self) { result in
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

        client.getEvents(addresses: nil,
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

        client.getEvents(addresses: nil,
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
