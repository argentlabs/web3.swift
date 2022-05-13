//
//  EthereumClient.swift
//  web3swift
//
//  Created by Julien Niset on 15/02/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation
import BigInt

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public enum CallResolution {
    case noOffchain(failOnExecutionError: Bool)
    case offchainAllowed(maxRedirects: Int)
}

public protocol EthereumClientProtocol: AnyObject {
    init(url: URL, sessionConfig: URLSessionConfiguration)
    init(url: URL)
    var network: EthereumNetwork? { get }

    func net_version(completion: @escaping((EthereumClientError?, EthereumNetwork?) -> Void))
    func eth_gasPrice(completion: @escaping((EthereumClientError?, BigUInt?) -> Void))
    func eth_blockNumber(completion: @escaping((EthereumClientError?, Int?) -> Void))
    func eth_getBalance(address: EthereumAddress, block: EthereumBlock, completion: @escaping((EthereumClientError?, BigUInt?) -> Void))
    func eth_getCode(address: EthereumAddress, block: EthereumBlock, completion: @escaping((EthereumClientError?, String?) -> Void))
    func eth_estimateGas(_ transaction: EthereumTransaction, withAccount account: EthereumAccountProtocol, completion: @escaping((EthereumClientError?, BigUInt?) -> Void))
    func eth_sendRawTransaction(_ transaction: EthereumTransaction, withAccount account: EthereumAccountProtocol, completion: @escaping((EthereumClientError?, String?) -> Void))
    func eth_getTransactionCount(address: EthereumAddress, block: EthereumBlock, completion: @escaping((EthereumClientError?, Int?) -> Void))
    func eth_getTransaction(byHash txHash: String, completion: @escaping((EthereumClientError?, EthereumTransaction?) -> Void))
    func eth_getTransactionReceipt(txHash: String, completion: @escaping((EthereumClientError?, EthereumTransactionReceipt?) -> Void))
    func eth_call(
        _ transaction: EthereumTransaction,
        resolution: CallResolution,
        block: EthereumBlock,
        completion: @escaping((EthereumClientError?, String?) -> Void)
    )
    func eth_getLogs(addresses: [EthereumAddress]?, topics: [String?]?, fromBlock: EthereumBlock, toBlock: EthereumBlock, completion: @escaping((EthereumClientError?, [EthereumLog]?) -> Void))
    func eth_getLogs(addresses: [EthereumAddress]?, orTopics: [[String]?]?, fromBlock: EthereumBlock, toBlock: EthereumBlock, completion: @escaping((EthereumClientError?, [EthereumLog]?) -> Void))
    func eth_getBlockByNumber(_ block: EthereumBlock, completion: @escaping((EthereumClientError?, EthereumBlockInfo?) -> Void))

#if compiler(>=5.5) && canImport(_Concurrency)
    @available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
    func net_version() async throws -> EthereumNetwork

    @available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
    func eth_gasPrice() async throws -> BigUInt

    @available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
    func eth_blockNumber() async throws -> Int

    @available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
    func eth_getBalance(address: EthereumAddress, block: EthereumBlock) async throws -> BigUInt

    @available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
    func eth_getCode(address: EthereumAddress, block: EthereumBlock) async throws -> String

    @available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
    func eth_estimateGas(_ transaction: EthereumTransaction, withAccount account: EthereumAccountProtocol) async throws -> BigUInt

    @available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
    func eth_sendRawTransaction(_ transaction: EthereumTransaction, withAccount account: EthereumAccountProtocol) async throws -> String

    @available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
    func eth_getTransactionCount(address: EthereumAddress, block: EthereumBlock) async throws -> Int

    @available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
    func eth_getTransaction(byHash txHash: String) async throws -> EthereumTransaction

    @available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
    func eth_getTransactionReceipt(txHash: String) async throws -> EthereumTransactionReceipt

    @available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
    func eth_call(
        _ transaction: EthereumTransaction,
        resolution: CallResolution,
        block: EthereumBlock
    ) async throws -> String

    @available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
    func eth_getLogs(addresses: [EthereumAddress]?, topics: [String?]?, fromBlock: EthereumBlock, toBlock: EthereumBlock) async throws ->  [EthereumLog]

    @available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
    func eth_getLogs(addresses: [EthereumAddress]?, orTopics: [[String]?]?, fromBlock: EthereumBlock, toBlock: EthereumBlock) async throws ->  [EthereumLog]

    @available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
    func eth_getBlockByNumber(_ block: EthereumBlock) async throws -> EthereumBlockInfo
#endif
}

public enum EthereumClientError: Error, Equatable {
    case tooManyResults
    case executionError(JSONRPCErrorDetail)
    case unexpectedReturnValue
    case noResultFound
    case decodeIssue
    case encodeIssue
    case noInputData
}

public class EthereumClient: EthereumClientProtocol {
    public let url: URL
    private var retreivedNetwork: EthereumNetwork?

    private let networkQueue: OperationQueue
    private let concurrentQueue: OperationQueue

    public let session: URLSession

    public var network: EthereumNetwork? {
        if let _ = self.retreivedNetwork {
            return self.retreivedNetwork
        }

        let group = DispatchGroup()
        group.enter()

        var network: EthereumNetwork?
        self.net_version { (error, retreivedNetwork) in
            if let error = error {
                print("Client has no network: \(error.localizedDescription)")
            } else {
                network = retreivedNetwork
                self.retreivedNetwork = network
            }

            group.leave()
        }

        group.wait()
        return network
    }

    required public init(url: URL, sessionConfig: URLSessionConfiguration) {
        self.url = url
        let networkQueue = OperationQueue()
        networkQueue.name = "web3swift.client.networkQueue"
        networkQueue.qualityOfService = .background
        networkQueue.maxConcurrentOperationCount = 4
        self.networkQueue = networkQueue

        let txQueue = OperationQueue()
        txQueue.name = "web3swift.client.rawTxQueue"
        txQueue.qualityOfService = .background
        txQueue.maxConcurrentOperationCount = 1
        self.concurrentQueue = txQueue

        self.session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: networkQueue)
    }

    required public convenience init(url: URL) {
        self.init(url: url, sessionConfig: URLSession.shared.configuration)
    }

    deinit {
        self.session.invalidateAndCancel()
    }

    public func net_version(completion: @escaping ((EthereumClientError?, EthereumNetwork?) -> Void)) {
        let emptyParams: Array<Bool> = []
        EthereumRPC.execute(session: session, url: url, method: "net_version", params: emptyParams, receive: String.self) { (error, response) in
            if let resString = response as? String {
                let network = EthereumNetwork.fromString(resString)
                completion(nil, network)
            } else {
                completion(EthereumClientError.unexpectedReturnValue, nil)
            }
        }
    }

    public func eth_gasPrice(completion: @escaping ((EthereumClientError?, BigUInt?) -> Void)) {
        let emptyParams: Array<Bool> = []
        EthereumRPC.execute(session: session, url: url, method: "eth_gasPrice", params: emptyParams, receive: String.self) { (error, response) in
            if let hexString = response as? String {
                completion(nil, BigUInt(hex: hexString))
            } else {
                completion(EthereumClientError.unexpectedReturnValue, nil)
            }
        }
    }

    public func eth_blockNumber(completion: @escaping ((EthereumClientError?, Int?) -> Void)) {
        let emptyParams: Array<Bool> = []
        EthereumRPC.execute(session: session, url: url, method: "eth_blockNumber", params: emptyParams, receive: String.self) { (error, response) in
            if let hexString = response as? String {
                if let integerValue = Int(hex: hexString) {
                    completion(nil, integerValue)
                } else {
                    completion(EthereumClientError.decodeIssue, nil)
                }
            } else {
                completion(EthereumClientError.unexpectedReturnValue, nil)
            }
        }
    }

    public func eth_getBalance(address: EthereumAddress, block: EthereumBlock, completion: @escaping ((EthereumClientError?, BigUInt?) -> Void)) {
        EthereumRPC.execute(session: session, url: url, method: "eth_getBalance", params: [address.value, block.stringValue], receive: String.self) { (error, response) in
            if let resString = response as? String, let balanceInt = BigUInt(hex: resString.web3.noHexPrefix) {
                completion(nil, balanceInt)
            } else {
                completion(EthereumClientError.unexpectedReturnValue, nil)
            }
        }
    }

    public func eth_getCode(address: EthereumAddress, block: EthereumBlock = .Latest, completion: @escaping((EthereumClientError?, String?) -> Void)) {
        EthereumRPC.execute(session: session, url: url, method: "eth_getCode", params: [address.value, block.stringValue], receive: String.self) { (error, response) in
            if let resDataString = response as? String {
                completion(nil, resDataString)
            } else {
                completion(EthereumClientError.unexpectedReturnValue, nil)
            }
        }
    }

    public func eth_estimateGas(_ transaction: EthereumTransaction, withAccount account: EthereumAccountProtocol, completion: @escaping((EthereumClientError?, BigUInt?) -> Void)) {

        struct CallParams: Encodable {
            let from: String?
            let to: String
            let gas: String?
            let gasPrice: String?
            let value: String?
            let data: String?

            enum TransactionCodingKeys: String, CodingKey {
                case from
                case to
                case gas
                case gasPrice
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

                if let gas = gas.map(jsonRPCAmount) {
                    try nested.encode(gas, forKey: .gas)
                }
                if let gasPrice = gasPrice.map(jsonRPCAmount) {
                    try nested.encode(gasPrice, forKey: .gasPrice)
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

        let params = CallParams(from: transaction.from?.value,
                                to: transaction.to.value,
                                gas: transaction.gasLimit?.web3.hexString,
                                gasPrice: transaction.gasPrice?.web3.hexString,
                                value: value?.web3.hexString,
                                data: transaction.data?.web3.hexString)
        EthereumRPC.execute(session: session, url: url, method: "eth_estimateGas", params: params, receive: String.self) { (error, response) in
            if let gasHex = response as? String, let gas = BigUInt(hex: gasHex) {
                completion(nil, gas)
            } else if case let .executionError(result) = error as? JSONRPCError {
                completion(.executionError(result.error), nil)
            } else {
                completion(.unexpectedReturnValue, nil)
            }
        }
    }

    public func eth_sendRawTransaction(_ transaction: EthereumTransaction, withAccount account: EthereumAccountProtocol, completion: @escaping ((EthereumClientError?, String?) -> Void)) {

        concurrentQueue.addOperation {
            let group = DispatchGroup()
            group.enter()

            // Inject pending nonce
            self.eth_getTransactionCount(address: account.address, block: .Pending) { (error, count) in
                guard let nonce = count else {
                    group.leave()
                    return completion(EthereumClientError.unexpectedReturnValue, nil)
                }

                var transaction = transaction
                transaction.nonce = nonce

                if transaction.chainId == nil, let network = self.network {
                    transaction.chainId = network.intValue
                }

                guard let _ = transaction.chainId, let signedTx = (try? account.sign(transaction: transaction)), let transactionHex = signedTx.raw?.web3.hexString else {
                    group.leave()
                    return completion(EthereumClientError.encodeIssue, nil)
                }

                EthereumRPC.execute(session: self.session, url: self.url, method: "eth_sendRawTransaction", params: [transactionHex], receive: String.self) { (error, response) in
                    group.leave()
                    if let resDataString = response as? String {
                        completion(nil, resDataString)
                    } else {
                        completion(EthereumClientError.unexpectedReturnValue, nil)
                    }
                }

            }
            group.wait()
        }
    }

    public func eth_getTransactionCount(address: EthereumAddress, block: EthereumBlock, completion: @escaping ((EthereumClientError?, Int?) -> Void)) {
        EthereumRPC.execute(session: session, url: url, method: "eth_getTransactionCount", params: [address.value, block.stringValue], receive: String.self) { (error, response) in
            if let resString = response as? String {
                let count = Int(hex: resString)
                completion(nil, count)
            } else {
                completion(EthereumClientError.unexpectedReturnValue, nil)
            }
        }
    }

    public func eth_getTransactionReceipt(txHash: String, completion: @escaping ((EthereumClientError?, EthereumTransactionReceipt?) -> Void)) {
        EthereumRPC.execute(session: session, url: url, method: "eth_getTransactionReceipt", params: [txHash], receive: EthereumTransactionReceipt.self) { (error, response) in
            if let receipt = response as? EthereumTransactionReceipt {
                completion(nil, receipt)
            } else if let _ = response {
                completion(EthereumClientError.noResultFound, nil)
            } else {
                completion(EthereumClientError.unexpectedReturnValue, nil)
            }
        }
    }

    public func eth_getTransaction(byHash txHash: String, completion: @escaping((EthereumClientError?, EthereumTransaction?) -> Void)) {

        EthereumRPC.execute(session: session, url: url, method: "eth_getTransactionByHash", params: [txHash], receive: EthereumTransaction.self) { (error, response) in
            if let transaction = response as? EthereumTransaction {
                completion(nil, transaction)
            } else {
                completion(EthereumClientError.unexpectedReturnValue, nil)
            }
        }
    }

    public func eth_getLogs(addresses: [EthereumAddress]?, topics: [String?]?, fromBlock from: EthereumBlock = .Earliest, toBlock to: EthereumBlock = .Latest, completion: @escaping ((EthereumClientError?, [EthereumLog]?) -> Void)) {
        eth_getLogs(addresses: addresses, topics: topics.map(Topics.plain), fromBlock: from, toBlock: to, completion: completion)
    }

    public func eth_getLogs(addresses: [EthereumAddress]?, orTopics topics: [[String]?]?, fromBlock from: EthereumBlock = .Earliest, toBlock to: EthereumBlock = .Latest, completion: @escaping((EthereumClientError?, [EthereumLog]?) -> Void)) {
        eth_getLogs(addresses: addresses, topics: topics.map(Topics.composed), fromBlock: from, toBlock: to, completion: completion)
    }

    private func eth_getLogs(addresses: [EthereumAddress]?, topics: Topics?, fromBlock from: EthereumBlock, toBlock to: EthereumBlock, completion: @escaping((EthereumClientError?, [EthereumLog]?) -> Void)) {
        DispatchQueue.global(qos: .default)
            .async {
                let result = RecursiveLogCollector(ethClient: self)
                    .getAllLogs(addresses: addresses, topics: topics, from: from, to: to)

                switch result {
                case .success(let logs):
                    completion(nil, logs)
                case .failure(let error):
                    completion(error, nil)
                }
            }
    }

    internal func getLogs(addresses: [EthereumAddress]?, topics: Topics?, fromBlock: EthereumBlock, toBlock: EthereumBlock, completion: @escaping((Result<[EthereumLog], EthereumClientError>) -> Void)) {

        struct CallParams: Encodable {
            var fromBlock: String
            var toBlock: String
            let address: [EthereumAddress]?
            let topics: Topics?
        }

        let params = CallParams(fromBlock: fromBlock.stringValue, toBlock: toBlock.stringValue, address: addresses, topics: topics)

        EthereumRPC.execute(session: session, url: url, method: "eth_getLogs", params: [params], receive: [EthereumLog].self) { (error, response) in
            if let logs = response as? [EthereumLog] {
                completion(.success(logs))
            } else {
                if let error = error as? JSONRPCError,
                   case let .executionError(innerError) = error,
                   innerError.error.code == JSONRPCErrorCode.tooManyResults {
                    completion(.failure(.tooManyResults))
                } else {
                    completion(.failure(.unexpectedReturnValue))
                }
            }
        }
    }

    public func eth_getBlockByNumber(_ block: EthereumBlock, completion: @escaping((EthereumClientError?, EthereumBlockInfo?) -> Void)) {

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

        EthereumRPC.execute(session: session, url: url, method: "eth_getBlockByNumber", params: params, receive: EthereumBlockInfo.self) { (error, response) in
            if let blockData = response as? EthereumBlockInfo {
                completion(nil, blockData)
            } else {
                completion(EthereumClientError.unexpectedReturnValue, nil)
            }
        }
    }
}

#if compiler(>=5.5) && canImport(_Concurrency)

@available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
extension EthereumClient {
    public func net_version() async throws -> EthereumNetwork {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<EthereumNetwork, Error>) in
            net_version { error, ethereumNetwork in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let ethereumNetwork = ethereumNetwork {
                    continuation.resume(returning: ethereumNetwork)
                }
            }
        }
    }

    public func eth_gasPrice() async throws -> BigUInt {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<BigUInt, Error>) in
            eth_gasPrice { error, gasPrice in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let gasPrice = gasPrice {
                    continuation.resume(returning: gasPrice)
                }
            }
        }
    }

    public func eth_blockNumber() async throws -> Int {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Int, Error>) in
            eth_blockNumber { error, blockNumber in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let blockNumber = blockNumber {
                    continuation.resume(returning: blockNumber)
                }
            }
        }
    }

    public func eth_getBalance(address: EthereumAddress, block: EthereumBlock) async throws -> BigUInt {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<BigUInt, Error>) in
            eth_getBalance(address: address, block: block) { error, balance in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let balance = balance {
                    continuation.resume(returning: balance)
                }
            }
        }
    }

    public func eth_getCode(address: EthereumAddress, block: EthereumBlock = .Latest) async throws -> String {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            eth_getCode(address: address, block: block) { error, code in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let code = code {
                    continuation.resume(returning: code)
                }
            }
        }
    }

    public func eth_estimateGas(_ transaction: EthereumTransaction, withAccount account: EthereumAccountProtocol) async throws -> BigUInt {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<BigUInt, Error>) in
            eth_estimateGas(transaction, withAccount: account) { error, gas in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let gas = gas {
                    continuation.resume(returning: gas)
                }
            }
        }
    }

    public func eth_sendRawTransaction(_ transaction: EthereumTransaction, withAccount account: EthereumAccountProtocol) async throws -> String {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            eth_sendRawTransaction(transaction, withAccount: account) { error, txHash in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let txHash = txHash {
                    continuation.resume(returning: txHash)
                }
            }
        }
    }

    public func eth_getTransactionCount(address: EthereumAddress, block: EthereumBlock) async throws -> Int {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Int, Error>) in
            eth_getTransactionCount(address: address, block: block) { error, count in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let count = count {
                    continuation.resume(returning: count)
                }
            }
        }
    }

    public func eth_getTransaction(byHash txHash: String) async throws -> EthereumTransaction {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<EthereumTransaction, Error>) in
            eth_getTransaction(byHash: txHash) { error, transaction in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let transaction = transaction {
                    continuation.resume(returning: transaction)
                }
            }
        }
    }

    public func eth_getTransactionReceipt(txHash: String) async throws -> EthereumTransactionReceipt {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<EthereumTransactionReceipt, Error>) in
            eth_getTransactionReceipt(txHash: txHash) { error, transactionReceipt in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let transactionReceipt = transactionReceipt {
                    continuation.resume(returning: transactionReceipt)
                }
            }
        }
    }

    public func eth_call(
        _ transaction: EthereumTransaction,
        resolution: CallResolution = .noOffchain(failOnExecutionError: true),
        block: EthereumBlock = .Latest) async throws -> String {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            eth_call(
                transaction,
                resolution: resolution,
                block: block
            ) { error, txHash in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let txHash = txHash {
                    continuation.resume(returning: txHash)
                }
            }
        }
    }

    public func eth_getLogs(addresses: [EthereumAddress]?, topics: [String?]?, fromBlock from: EthereumBlock = .Earliest, toBlock to: EthereumBlock = .Latest) async throws -> [EthereumLog] {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[EthereumLog], Error>) in
            eth_getLogs(addresses: addresses, topics: topics, fromBlock: from, toBlock: to) { error, logs in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let logs = logs {
                    continuation.resume(returning: logs)
                }
            }
        }
    }

    public func eth_getLogs(addresses: [EthereumAddress]?, orTopics topics: [[String]?]?, fromBlock from: EthereumBlock = .Earliest, toBlock to: EthereumBlock = .Latest) async throws ->  [EthereumLog] {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[EthereumLog], Error>) in
            eth_getLogs(addresses: addresses, orTopics: topics, fromBlock: from, toBlock: to) { error, logs in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let logs = logs {
                    continuation.resume(returning: logs)
                }
            }
        }
    }

    public func eth_getBlockByNumber(_ block: EthereumBlock) async throws -> EthereumBlockInfo {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<EthereumBlockInfo, Error>) in
            eth_getBlockByNumber(block) { error, blockInfo in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let blockInfo = blockInfo {
                    continuation.resume(returning: blockInfo)
                }
            }
        }
    }
}
#endif
