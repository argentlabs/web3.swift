//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import BigInt

public struct EquatableError: Error, Equatable {
    let base: Error

    public static func == (lhs: EquatableError, rhs: EquatableError) -> Bool {
        type(of: lhs.base) == type(of: rhs.base) &&
            lhs.base.localizedDescription == rhs.base.localizedDescription
    }
}

public enum EthereumClientError: Error, Equatable {
    case tooManyResults
    case executionError(JSONRPCErrorDetail)
    case unexpectedReturnValue
    case noResultFound
    case decodeIssue
    case encodeIssue
    case noInputData
    case webSocketError(EquatableError)
    case connectionNotOpen
}

public protocol EthereumRPCProtocol: AnyObject {
    var networkProvider: NetworkProviderProtocol { get }
    var network: EthereumNetwork { get }

    func eth_getTransactionCount(address: EthereumAddress, block: EthereumBlock) async throws -> Int
    func net_version() async throws -> EthereumNetwork
    func eth_gasPrice() async throws -> BigUInt
    func eth_blockNumber() async throws -> Int
    func eth_getBalance(address: EthereumAddress, block: EthereumBlock) async throws -> BigUInt
    func eth_getCode(address: EthereumAddress, block: EthereumBlock) async throws -> String
    func eth_estimateGas(_ transaction: EthereumTransaction) async throws -> BigUInt
    func eth_sendRawTransaction(_ transaction: EthereumTransaction, withAccount account: EthereumAccountProtocol) async throws -> String
    func eth_getTransaction(byHash txHash: String) async throws -> EthereumTransaction
    func eth_getTransactionReceipt(txHash: String) async throws -> EthereumTransactionReceipt
    func eth_call(
        _ transaction: EthereumTransaction,
        block: EthereumBlock
    ) async throws -> String
    func eth_call(
        _ transaction: EthereumTransaction,
        resolution: CallResolution,
        block: EthereumBlock
    ) async throws -> String
    func eth_getLogs(addresses: [EthereumAddress]?, topics: [String?]?, fromBlock: EthereumBlock, toBlock: EthereumBlock) async throws -> [EthereumLog]
    func eth_getLogs(addresses: [EthereumAddress]?, orTopics: [[String]?]?, fromBlock: EthereumBlock, toBlock: EthereumBlock) async throws -> [EthereumLog]
    func eth_getBlockByNumber(_ block: EthereumBlock) async throws -> EthereumBlockInfo
}

extension EthereumRPCProtocol {
    public func eth_getTransactionCount(address: EthereumAddress, block: EthereumBlock) async throws -> Int {
        do {
            let data = try await networkProvider.send(method: "eth_getTransactionCount", params: [address.asString(), block.stringValue], receive: String.self)
            if let resString = data as? String, let count = Int(hex: resString) {
                return count
            } else {
                throw EthereumClientError.unexpectedReturnValue
            }
        } catch {
            throw failureHandler(error)
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
            let data = try await networkProvider.send(method: "eth_getBalance", params: [address.asString(), block.stringValue], receive: String.self)
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
            let data = try await networkProvider.send(method: "eth_getCode", params: [address.asString(), block.stringValue], receive: String.self)
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
        let value: BigUInt?
        if let txValue = transaction.value, txValue > .zero {
            value = txValue
        } else {
            value = nil
        }

        let params = EstimateCallParams(
            from: transaction.from?.asString(),
            to: transaction.to.asString(),
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

            if transaction.chainId == nil {
                transaction.chainId = network.intValue
            }

            guard let _ = transaction.chainId, let signedTx = (try? account.sign(transaction: transaction)), let transactionHex = signedTx.raw?.web3.hexString else {
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
        let params = GetLogsCallParams(fromBlock: fromBlock.stringValue, toBlock: toBlock.stringValue, address: addresses, topics: topics)

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
        let params = GetBlockByNumberCallParams(block: block, fullTransactions: false)

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

fileprivate struct EstimateCallParams: Encodable {
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

fileprivate struct GetLogsCallParams: Encodable {
    var fromBlock: String
    var toBlock: String
    let address: [EthereumAddress]?
    let topics: Topics?
}

fileprivate struct GetBlockByNumberCallParams: Encodable {
    let block: EthereumBlock
    let fullTransactions: Bool

    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(block.stringValue)
        try container.encode(fullTransactions)
    }
}
