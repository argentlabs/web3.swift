//
//  web3.swift
//  Copyright © Argent Labs Limited. All rights reserved.
//

import BigInt
import Logging
import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

open class BaseEthereumClient: EthereumClientProtocol, @unchecked Sendable {
    public let url: URL

    public let networkProvider: NetworkProviderProtocol

    private let logger: Logger

    public var network: EthereumNetwork

    public init(
        networkProvider: NetworkProviderProtocol,
        url: URL,
        logger: Logger? = nil,
        network: EthereumNetwork
    ) {
        self.url = url
        self.networkProvider = networkProvider
        self.logger = logger ?? Logger(label: "web3.swift.eth-client")
        self.network = network
    }

    func failureHandler(_ error: Error) -> EthereumClientError {
        if case let .executionError(result) = error as? JSONRPCError {
            EthereumClientError.executionError(result.error)
        } else if case .executionError = error as? EthereumClientError, let error = error as? EthereumClientError {
            error
        } else {
            EthereumClientError.unexpectedReturnValue
        }
    }
}

extension BaseEthereumClient {
    public func net_version(completionHandler: @Sendable @escaping (Result<EthereumNetwork, EthereumClientError>) -> Void) {
        Task {
            do {
                let result = try await net_version()
                completionHandler(.success(result))
            } catch {
                failureHandler(error, completionHandler: completionHandler)
            }
        }
    }

    public func eth_gasPrice(completionHandler: @Sendable @escaping (Result<BigUInt, EthereumClientError>) -> Void) {
        Task {
            do {
                let result = try await eth_gasPrice()
                completionHandler(.success(result))
            } catch {
                failureHandler(error, completionHandler: completionHandler)
            }
        }
    }

    public func eth_blockNumber(completionHandler: @Sendable @escaping (Result<Int, EthereumClientError>) -> Void) {
        Task {
            do {
                let result = try await eth_blockNumber()
                completionHandler(.success(result))
            } catch {
                failureHandler(error, completionHandler: completionHandler)
            }
        }
    }

    public func eth_getBalance(address: EthereumAddress, block: EthereumBlock, completionHandler: @Sendable @escaping (Result<BigUInt, EthereumClientError>) -> Void) {
        Task {
            do {
                let result = try await eth_getBalance(address: address, block: block)
                completionHandler(.success(result))
            } catch {
                failureHandler(error, completionHandler: completionHandler)
            }
        }
    }

    public func eth_getCode(address: EthereumAddress, block: EthereumBlock = .Latest, completionHandler: @Sendable @escaping (Result<String, EthereumClientError>) -> Void) {
        Task {
            do {
                let result = try await eth_getCode(address: address, block: block)
                completionHandler(.success(result))
            } catch {
                failureHandler(error, completionHandler: completionHandler)
            }
        }
    }

    public func eth_estimateGas(_ transaction: EthereumTransaction, completionHandler: @Sendable @escaping (Result<BigUInt, EthereumClientError>) -> Void) {
        Task {
            do {
                let result = try await eth_estimateGas(transaction)
                completionHandler(.success(result))
            } catch {
                failureHandler(error, completionHandler: completionHandler)
            }
        }
    }

    public func eth_getTransactionCount(address: EthereumAddress, block: EthereumBlock, completionHandler: @Sendable @escaping (Result<Int, EthereumClientError>) -> Void) {
        Task {
            do {
                let result = try await eth_getTransactionCount(address: address, block: block)
                completionHandler(.success(result))
            } catch {
                failureHandler(error, completionHandler: completionHandler)
            }
        }
    }

    public func eth_getTransaction(byHash txHash: String, completionHandler: @Sendable @escaping (Result<EthereumTransaction, EthereumClientError>) -> Void) {
        Task {
            do {
                let result = try await eth_getTransaction(byHash: txHash)
                completionHandler(.success(result))
            } catch {
                failureHandler(error, completionHandler: completionHandler)
            }
        }
    }

    public func eth_getTransactionReceipt(txHash: String, completionHandler: @Sendable @escaping (Result<EthereumTransactionReceipt, EthereumClientError>) -> Void) {
        Task {
            do {
                let result = try await eth_getTransactionReceipt(txHash: txHash)
                completionHandler(.success(result))
            } catch {
                failureHandler(error, completionHandler: completionHandler)
            }
        }
    }

    public func eth_getBlockByNumber(_ block: EthereumBlock, completionHandler: @Sendable @escaping (Result<EthereumBlockInfo, EthereumClientError>) -> Void) {
        Task {
            do {
                let result = try await eth_getBlockByNumber(block)
                completionHandler(.success(result))
            } catch {
                failureHandler(error, completionHandler: completionHandler)
            }
        }
    }

    public func eth_sendRawTransaction(_ transaction: EthereumTransaction, withAccount account: EthereumAccountProtocol, completionHandler: @Sendable @escaping (Result<String, EthereumClientError>) -> Void) {
        Task {
            do {
                let result = try await eth_sendRawTransaction(transaction, withAccount: account)
                completionHandler(.success(result))
            } catch {
                failureHandler(error, completionHandler: completionHandler)
            }
        }
    }

    public func eth_getLogs(addresses: [EthereumAddress]?, topics: [String?]?, fromBlock from: EthereumBlock = .Earliest, toBlock to: EthereumBlock = .Latest, completionHandler: @Sendable @escaping (Result<[EthereumLog], EthereumClientError>) -> Void) {
        Task {
            do {
                let result = try await eth_getLogs(addresses: addresses, topics: topics, fromBlock: from, toBlock: to)
                completionHandler(.success(result))
            } catch {
                failureHandler(error, completionHandler: completionHandler)
            }
        }
    }

    public func eth_getLogs(addresses: [EthereumAddress]?, orTopics topics: [[String]?]?, fromBlock from: EthereumBlock = .Earliest, toBlock to: EthereumBlock = .Latest, completionHandler: @Sendable @escaping (Result<[EthereumLog], EthereumClientError>) -> Void) {
        Task {
            do {
                let result = try await eth_getLogs(addresses: addresses, orTopics: topics, fromBlock: from, toBlock: to)
                completionHandler(.success(result))
            } catch {
                failureHandler(error, completionHandler: completionHandler)
            }
        }
    }

    func failureHandler<T>(_ error: Error, completionHandler: @Sendable @escaping (Result<T, EthereumClientError>) -> Void) {
        if case let .executionError(result) = error as? JSONRPCError {
            completionHandler(.failure(.executionError(result.error)))
        } else if case .executionError = error as? EthereumClientError, let error = error as? EthereumClientError {
            completionHandler(.failure(error))
        } else {
            completionHandler(.failure(.unexpectedReturnValue))
        }
    }
}
