//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import BigInt
import Logging
import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

public class BaseEthereumClient: EthereumClientProtocol {
    public let url: URL

    let networkProvider: NetworkProviderProtocol

    private let logger: Logger

    public var network: EthereumNetwork?

    init(
        networkProvider: NetworkProviderProtocol,
        url: URL,
        logger: Logger? = nil,
        network: EthereumNetwork?
    ) {
        self.url = url
        self.networkProvider = networkProvider
        self.logger = logger ?? Logger(label: "web3.swift.eth-client")
        self.network = network

        if network == nil {
            let semaphore = DispatchSemaphore(value: 0)
            Task {
                self.network = await fetchNetwork()
                semaphore.signal()
            }
            semaphore.wait()
        }
    }

    public func net_version() async throws -> EthereumNetwork {
        let emptyParams: [Bool] = []
        do {
            let data = try await networkProvider.send(method: "net_version", params: emptyParams, receive: String.self)

            if let resString = data as? String {
                let network = EthereumNetwork.fromString(resString)
                return network
            } else {
                throw EthereumClientError.unexpectedReturnValue
            }
        } catch {
            throw failureHandler(error)
        }
    }

    public func eth_gasPrice() async throws -> BigUInt {
        let emptyParams: [Bool] = []

        do {
            let data = try await networkProvider.send(method: "eth_gasPrice", params: emptyParams, receive: String.self)
            if let hexString = data as? String, let bigUInt = BigUInt(hex: hexString) {
                return bigUInt
            } else {
                throw EthereumClientError.unexpectedReturnValue
            }
        } catch {
            throw failureHandler(error)
        }
    }

    public func eth_blockNumber() async throws -> Int {
        let emptyParams: [Bool] = []

        do {
            let data = try await networkProvider.send(method: "eth_blockNumber", params: emptyParams, receive: String.self)
            if let hexString = data as? String {
                if let integerValue = Int(hex: hexString) {
                    return integerValue
                } else {
                    throw EthereumClientError.decodeIssue
                }
            } else {
                throw EthereumClientError.unexpectedReturnValue
            }
        } catch {
            throw failureHandler(error)
        }
    }

    public func eth_getBalance(address: EthereumAddress, block: EthereumBlock) async throws -> BigUInt {
        do {
            let data = try await networkProvider.send(method: "eth_getBalance", params: [address.value, block.stringValue], receive: String.self)
            if let resString = data as? String, let balanceInt = BigUInt(hex: resString.web3.noHexPrefix) {
                return balanceInt
            } else {
                throw EthereumClientError.unexpectedReturnValue
            }
        } catch {
            throw failureHandler(error)
        }
    }

    public func eth_getCode(address: EthereumAddress, block: EthereumBlock = .Latest) async throws -> String {
        do {
            let data = try await networkProvider.send(method: "eth_getCode", params: [address.value, block.stringValue], receive: String.self)
            if let resDataString = data as? String {
                return resDataString
            } else {
                throw EthereumClientError.unexpectedReturnValue
            }
        } catch {
            throw failureHandler(error)
        }
    }

    public func eth_estimateGas(_ transaction: EthereumTransaction) async throws -> BigUInt {
        struct CallParams: Encodable {
            let from: String?
            let to: String
            let value: String?
            let data: String?

            enum TransactionCodingKeys: String, CodingKey {
                case from
                case to
                case value
                case data
            }

            func encode(to encoder: Encoder) throws {
                var container = encoder.unkeyedContainer()
                var nested = container.nestedContainer(keyedBy: TransactionCodingKeys.self)
                if let from = from {
                    try nested.encode(from, forKey: .from)
                }
                try nested.encode(to, forKey: .to)

                let jsonRPCAmount: (String) -> String = { amount in
                    amount == "0x00" ? "0x0" : amount
                }

                if let value = value.map(jsonRPCAmount) {
                    try nested.encode(value, forKey: .value)
                }
                if let data = data {
                    try nested.encode(data, forKey: .data)
                }
            }
        }

        let value: BigUInt?
        if let txValue = transaction.value, txValue > .zero {
            value = txValue
        } else {
            value = nil
        }

        let params = CallParams(
            from: transaction.from?.value,
            to: transaction.to.value,
            value: value?.web3.hexStringNoLeadingZeroes,
            data: transaction.data?.web3.hexString
        )

        do {
            let data = try await networkProvider.send(method: "eth_estimateGas", params: params, receive: String.self)
            if let gasHex = data as? String, let gas = BigUInt(hex: gasHex) {
                return gas
            } else {
                throw EthereumClientError.unexpectedReturnValue
            }
        } catch {
            throw failureHandler(error)
        }
    }

    public func eth_sendRawTransaction(_ transaction: EthereumTransaction, withAccount account: EthereumAccountProtocol) async throws -> String {
        do {
            // Inject pending nonce
            let nonce = try await eth_getTransactionCount(address: account.address, block: .Pending)

            var transaction = transaction
            transaction.nonce = nonce

            if transaction.chainId == nil, let network = network {
                transaction.chainId = network.intValue
            }

            guard let _ = transaction.chainId, let signedTx = (try? await account.sign(transaction: transaction)), let transactionHex = signedTx.raw?.web3.hexString else {
                throw EthereumClientError.encodeIssue
            }

            let data = try await networkProvider.send(method: "eth_sendRawTransaction", params: [transactionHex], receive: String.self)
            if let resDataString = data as? String {
                return resDataString
            } else {
                throw EthereumClientError.unexpectedReturnValue
            }
        } catch {
            throw failureHandler(error)
        }
    }

    public func eth_getTransactionCount(address: EthereumAddress, block: EthereumBlock) async throws -> Int {
        do {
            let data = try await networkProvider.send(method: "eth_getTransactionCount", params: [address.value, block.stringValue], receive: String.self)
            if let resString = data as? String, let count = Int(hex: resString) {
                return count
            } else {
                throw EthereumClientError.unexpectedReturnValue
            }
        } catch {
            throw failureHandler(error)
        }
    }

    public func eth_getTransaction(byHash txHash: String) async throws -> EthereumTransaction {
        do {
            let data = try await networkProvider.send(method: "eth_getTransactionByHash", params: [txHash], receive: EthereumTransaction.self)
            if let transaction = data as? EthereumTransaction {
                return transaction
            } else {
                throw EthereumClientError.unexpectedReturnValue
            }
        } catch {
            throw failureHandler(error)
        }
    }

    public func eth_getTransactionReceipt(txHash: String) async throws -> EthereumTransactionReceipt {
        do {
            let data = try await networkProvider.send(method: "eth_getTransactionReceipt", params: [txHash], receive: EthereumTransactionReceipt.self)
            if let receipt = data as? EthereumTransactionReceipt {
                return receipt
            } else {
                throw EthereumClientError.unexpectedReturnValue
            }
        } catch {
            throw failureHandler(error)
        }
    }

    public func eth_getLogs(addresses: [EthereumAddress]?, topics: [String?]?, fromBlock from: EthereumBlock = .Earliest, toBlock to: EthereumBlock = .Latest) async throws -> [EthereumLog] {
        try await RecursiveLogCollector(ethClient: self).getAllLogs(addresses: addresses, topics: topics.map(Topics.plain), from: from, to: to)
    }

    public func eth_getLogs(addresses: [EthereumAddress]?, orTopics topics: [[String]?]?, fromBlock from: EthereumBlock = .Earliest, toBlock to: EthereumBlock = .Latest) async throws -> [EthereumLog] {
        try await RecursiveLogCollector(ethClient: self).getAllLogs(addresses: addresses, topics: topics.map(Topics.composed), from: from, to: to)
    }

    public func getLogs(addresses: [EthereumAddress]?, topics: Topics?, fromBlock: EthereumBlock, toBlock: EthereumBlock) async throws -> [EthereumLog] {
        struct CallParams: Encodable {
            var fromBlock: String
            var toBlock: String
            let address: [EthereumAddress]?
            let topics: Topics?
        }

        let params = CallParams(fromBlock: fromBlock.stringValue, toBlock: toBlock.stringValue, address: addresses, topics: topics)

        do {
            let data = try await networkProvider.send(method: "eth_getLogs", params: [params], receive: [EthereumLog].self)

            if let logs = data as? [EthereumLog] {
                return logs
            } else {
                throw EthereumClientError.unexpectedReturnValue
            }
        } catch {
            if let error = error as? JSONRPCError,
               case let .executionError(innerError) = error,
               innerError.error.code == JSONRPCErrorCode.tooManyResults {
                throw EthereumClientError.tooManyResults
            } else {
                throw EthereumClientError.unexpectedReturnValue
            }
        }
    }

    public func eth_getBlockByNumber(_ block: EthereumBlock) async throws -> EthereumBlockInfo {
        struct CallParams: Encodable {
            let block: EthereumBlock
            let fullTransactions: Bool

            func encode(to encoder: Encoder) throws {
                var container = encoder.unkeyedContainer()
                try container.encode(block.stringValue)
                try container.encode(fullTransactions)
            }
        }

        let params = CallParams(block: block, fullTransactions: false)

        do {
            let data = try await networkProvider.send(method: "eth_getBlockByNumber", params: params, receive: EthereumBlockInfo.self)
            if let blockData = data as? EthereumBlockInfo {
                return blockData
            } else {
                throw EthereumClientError.unexpectedReturnValue
            }
        } catch {
            throw failureHandler(error)
        }
    }

    private func fetchNetwork() async -> EthereumNetwork? {
        do {
            return try await net_version()
        } catch {
            logger.warning("Client has no network: \(error.localizedDescription)")
        }

        return nil
    }

    func failureHandler(_ error: Error) -> EthereumClientError {
        if case let .executionError(result) = error as? JSONRPCError {
            return EthereumClientError.executionError(result.error)
        } else if case .executionError = error as? EthereumClientError, let error = error as? EthereumClientError {
            return error
        } else {
            return EthereumClientError.unexpectedReturnValue
        }
    }
}

extension BaseEthereumClient {
    public func net_version(completionHandler: @escaping (Result<EthereumNetwork, EthereumClientError>) -> Void) {
        Task {
            do {
                let result = try await net_version()
                completionHandler(.success(result))
            } catch {
                failureHandler(error, completionHandler: completionHandler)
            }
        }
    }

    public func eth_gasPrice(completionHandler: @escaping (Result<BigUInt, EthereumClientError>) -> Void) {
        Task {
            do {
                let result = try await eth_gasPrice()
                completionHandler(.success(result))
            } catch {
                failureHandler(error, completionHandler: completionHandler)
            }
        }
    }

    public func eth_blockNumber(completionHandler: @escaping (Result<Int, EthereumClientError>) -> Void) {
        Task {
            do {
                let result = try await eth_blockNumber()
                completionHandler(.success(result))
            } catch {
                failureHandler(error, completionHandler: completionHandler)
            }
        }
    }

    public func eth_getBalance(address: EthereumAddress, block: EthereumBlock, completionHandler: @escaping (Result<BigUInt, EthereumClientError>) -> Void) {
        Task {
            do {
                let result = try await eth_getBalance(address: address, block: block)
                completionHandler(.success(result))
            } catch {
                failureHandler(error, completionHandler: completionHandler)
            }
        }
    }

    public func eth_getCode(address: EthereumAddress, block: EthereumBlock = .Latest, completionHandler: @escaping (Result<String, EthereumClientError>) -> Void) {
        Task {
            do {
                let result = try await eth_getCode(address: address, block: block)
                completionHandler(.success(result))
            } catch {
                failureHandler(error, completionHandler: completionHandler)
            }
        }
    }

    public func eth_estimateGas(_ transaction: EthereumTransaction, completionHandler: @escaping (Result<BigUInt, EthereumClientError>) -> Void) {
        Task {
            do {
                let result = try await eth_estimateGas(transaction)
                completionHandler(.success(result))
            } catch {
                failureHandler(error, completionHandler: completionHandler)
            }
        }
    }

    public func eth_getTransactionCount(address: EthereumAddress, block: EthereumBlock, completionHandler: @escaping (Result<Int, EthereumClientError>) -> Void) {
        Task {
            do {
                let result = try await eth_getTransactionCount(address: address, block: block)
                completionHandler(.success(result))
            } catch {
                failureHandler(error, completionHandler: completionHandler)
            }
        }
    }

    public func eth_getTransaction(byHash txHash: String, completionHandler: @escaping (Result<EthereumTransaction, EthereumClientError>) -> Void) {
        Task {
            do {
                let result = try await eth_getTransaction(byHash: txHash)
                completionHandler(.success(result))
            } catch {
                failureHandler(error, completionHandler: completionHandler)
            }
        }
    }

    public func eth_getTransactionReceipt(txHash: String, completionHandler: @escaping (Result<EthereumTransactionReceipt, EthereumClientError>) -> Void) {
        Task {
            do {
                let result = try await eth_getTransactionReceipt(txHash: txHash)
                completionHandler(.success(result))
            } catch {
                failureHandler(error, completionHandler: completionHandler)
            }
        }
    }

    public func eth_getBlockByNumber(_ block: EthereumBlock, completionHandler: @escaping (Result<EthereumBlockInfo, EthereumClientError>) -> Void) {
        Task {
            do {
                let result = try await eth_getBlockByNumber(block)
                completionHandler(.success(result))
            } catch {
                failureHandler(error, completionHandler: completionHandler)
            }
        }
    }

    public func eth_sendRawTransaction(_ transaction: EthereumTransaction, withAccount account: EthereumAccountProtocol, completionHandler: @escaping (Result<String, EthereumClientError>) -> Void) {
        Task {
            do {
                let result = try await eth_sendRawTransaction(transaction, withAccount: account)
                completionHandler(.success(result))
            } catch {
                failureHandler(error, completionHandler: completionHandler)
            }
        }
    }

    public func eth_getLogs(addresses: [EthereumAddress]?, topics: [String?]?, fromBlock from: EthereumBlock = .Earliest, toBlock to: EthereumBlock = .Latest, completionHandler: @escaping (Result<[EthereumLog], EthereumClientError>) -> Void) {
        Task {
            do {
                let result = try await eth_getLogs(addresses: addresses, topics: topics, fromBlock: from, toBlock: to)
                completionHandler(.success(result))
            } catch {
                failureHandler(error, completionHandler: completionHandler)
            }
        }
    }

    public func eth_getLogs(addresses: [EthereumAddress]?, orTopics topics: [[String]?]?, fromBlock from: EthereumBlock = .Earliest, toBlock to: EthereumBlock = .Latest, completionHandler: @escaping (Result<[EthereumLog], EthereumClientError>) -> Void) {
        Task {
            do {
                let result = try await eth_getLogs(addresses: addresses, orTopics: topics, fromBlock: from, toBlock: to)
                completionHandler(.success(result))
            } catch {
                failureHandler(error, completionHandler: completionHandler)
            }
        }
    }

    func failureHandler<T>(_ error: Error, completionHandler: @escaping (Result<T, EthereumClientError>) -> Void) {
        if case let .executionError(result) = error as? JSONRPCError {
            completionHandler(.failure(.executionError(result.error)))
        } else if case .executionError = error as? EthereumClientError, let error = error as? EthereumClientError {
            completionHandler(.failure(error))
        } else {
            completionHandler(.failure(.unexpectedReturnValue))
        }
    }
}
