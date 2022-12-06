//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import BigInt
import Foundation

public protocol ERC20Protocol {
    init(client: EthereumClientProtocol)

    func name(tokenContract: EthereumAddress) async throws -> String
    func symbol(tokenContract: EthereumAddress) async throws -> String
    func decimals(tokenContract: EthereumAddress) async throws -> UInt8
    func balanceOf(tokenContract: EthereumAddress, address: EthereumAddress) async throws -> BigUInt
    func allowance(tokenContract: EthereumAddress, address: EthereumAddress, spender: EthereumAddress) async throws -> BigUInt
    func transferEventsTo(recipient: EthereumAddress, fromBlock: EthereumBlock, toBlock: EthereumBlock) async throws -> [ERC20Events.Transfer]
    func transferEventsFrom(sender: EthereumAddress, fromBlock: EthereumBlock, toBlock: EthereumBlock) async throws -> [ERC20Events.Transfer]

    // Deprecated
    func name(tokenContract: EthereumAddress, completionHandler: @escaping (Result<String, Error>) -> Void)
    func symbol(tokenContract: EthereumAddress, completionHandler: @escaping (Result<String, Error>) -> Void)
    func decimals(tokenContract: EthereumAddress, completionHandler: @escaping (Result<UInt8, Error>) -> Void)
    func balanceOf(tokenContract: EthereumAddress, address: EthereumAddress, completionHandler: @escaping (Result<BigUInt, Error>) -> Void)
    func allowance(tokenContract: EthereumAddress, address: EthereumAddress, spender: EthereumAddress, completionHandler: @escaping (Result<BigUInt, Error>) -> Void)
    func transferEventsTo(recipient: EthereumAddress, fromBlock: EthereumBlock, toBlock: EthereumBlock, completionHandler: @escaping (Result<[ERC20Events.Transfer], Error>) -> Void)
    func transferEventsFrom(sender: EthereumAddress, fromBlock: EthereumBlock, toBlock: EthereumBlock, completionHandler: @escaping (Result<[ERC20Events.Transfer], Error>) -> Void)
}

open class ERC20: ERC20Protocol {
    let client: EthereumClientProtocol

    required public init(client: EthereumClientProtocol) {
        self.client = client
    }

    public func name(tokenContract: EthereumAddress) async throws -> String {
        let function = ERC20Functions.name(contract: tokenContract)
        let data = try await function.call(withClient: client, responseType: ERC20Responses.nameResponse.self)
        return data.value
    }

    public func symbol(tokenContract: EthereumAddress) async throws -> String {
        let function = ERC20Functions.symbol(contract: tokenContract)
        let data = try await function.call(withClient: client, responseType: ERC20Responses.symbolResponse.self)
        return data.value
    }

    public func decimals(tokenContract: EthereumAddress) async throws -> UInt8 {
        let function = ERC20Functions.decimals(contract: tokenContract)
        let data = try await function.call(
            withClient: client,
            responseType: ERC20Responses.decimalsResponse.self,
            resolution: .noOffchain(failOnExecutionError: false)
        )
        return data.value
    }

    public func balanceOf(tokenContract: EthereumAddress, address: EthereumAddress) async throws -> BigUInt {
        let function = ERC20Functions.balanceOf(contract: tokenContract, account: address)
        let data = try await function.call(withClient: client, responseType: ERC20Responses.balanceResponse.self)
        return data.value
    }

    public func allowance(tokenContract: EthereumAddress, address: EthereumAddress, spender: EthereumAddress) async throws -> BigUInt {
        let function = ERC20Functions.allowance(contract: tokenContract, owner: address, spender: spender)
        let data = try await function.call(withClient: client, responseType: ERC20Responses.balanceResponse.self)
        return data.value
    }

    public func transferEventsTo(recipient: EthereumAddress, fromBlock: EthereumBlock, toBlock: EthereumBlock) async throws -> [ERC20Events.Transfer] {
        guard let result = try? ABIEncoder.encode(recipient).bytes, let sig = try? ERC20Events.Transfer.signature() else {
            throw EthereumSignerError.unknownError
        }

        let data = try await client.getEvents(
            addresses: nil,
            topics: [sig, nil, String(hexFromBytes: result)],
            fromBlock: fromBlock,
            toBlock: toBlock,
            eventTypes: [ERC20Events.Transfer.self]
        )

        if let events = data.events as? [ERC20Events.Transfer] {
            return events
        } else {
            throw EthereumClientError.decodeIssue
        }
    }

    public func transferEventsFrom(sender: EthereumAddress, fromBlock: EthereumBlock, toBlock: EthereumBlock) async throws -> [ERC20Events.Transfer] {
        guard let result = try? ABIEncoder.encode(sender).bytes, let sig = try? ERC20Events.Transfer.signature() else {
            throw EthereumSignerError.unknownError
        }

        let data = try await client.getEvents(
            addresses: nil,
            topics: [sig, String(hexFromBytes: result), nil],
            fromBlock: fromBlock,
            toBlock: toBlock,
            eventTypes: [ERC20Events.Transfer.self]
        )

        if let events = data.events as? [ERC20Events.Transfer] {
            return events
        } else {
            throw EthereumClientError.decodeIssue
        }
    }
}

extension ERC20 {
    public func name(tokenContract: EthereumAddress, completionHandler: @escaping (Result<String, Error>) -> Void) {
        Task {
            do {
                let name = try await name(tokenContract: tokenContract)
                completionHandler(.success(name))
            } catch {
                completionHandler(.failure(error))
            }
        }
    }

    public func symbol(tokenContract: EthereumAddress, completionHandler: @escaping (Result<String, Error>) -> Void) {
        Task {
            do {
                let symbol = try await symbol(tokenContract: tokenContract)
                completionHandler(.success(symbol))
            } catch {
                completionHandler(.failure(error))
            }
        }
    }

    public func decimals(tokenContract: EthereumAddress, completionHandler: @escaping (Result<UInt8, Error>) -> Void) {
        Task {
            do {
                let decimals = try await decimals(tokenContract: tokenContract)
                completionHandler(.success(decimals))
            } catch {
                completionHandler(.failure(error))
            }
        }
    }

    public func balanceOf(tokenContract: EthereumAddress, address: EthereumAddress, completionHandler: @escaping (Result<BigUInt, Error>) -> Void) {
        Task {
            do {
                let balance = try await balanceOf(tokenContract: tokenContract, address: address)
                completionHandler(.success(balance))
            } catch {
                completionHandler(.failure(error))
            }
        }
    }

    public func allowance(tokenContract: EthereumAddress, address: EthereumAddress, spender: EthereumAddress, completionHandler: @escaping (Result<BigUInt, Error>) -> Void) {
        Task {
            do {
                let allowance = try await allowance(tokenContract: tokenContract, address: address, spender: spender)
                completionHandler(.success(allowance))
            } catch {
                completionHandler(.failure(error))
            }
        }
    }

    public func transferEventsTo(recipient: EthereumAddress, fromBlock: EthereumBlock, toBlock: EthereumBlock, completionHandler: @escaping (Result<[ERC20Events.Transfer], Error>) -> Void) {
        Task {
            do {
                let events = try await transferEventsTo(recipient: recipient, fromBlock: fromBlock, toBlock: toBlock)
                completionHandler(.success(events))
            } catch {
                completionHandler(.failure(error))
            }
        }
    }

    public func transferEventsFrom(sender: EthereumAddress, fromBlock: EthereumBlock, toBlock: EthereumBlock, completionHandler: @escaping (Result<[ERC20Events.Transfer], Error>) -> Void) {
        Task {
            do {
                let events = try await transferEventsFrom(sender: sender, fromBlock: fromBlock, toBlock: toBlock)
                completionHandler(.success(events))
            } catch {
                completionHandler(.failure(error))
            }
        }
    }
}
