//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
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

    func net_version(completionHandler: @escaping(Result<EthereumNetwork, EthereumClientError>) -> Void)
    func eth_gasPrice(completionHandler: @escaping(Result<BigUInt, EthereumClientError>) -> Void)
    func eth_blockNumber(completionHandler: @escaping(Result<Int, EthereumClientError>) -> Void)
    func eth_getBalance(address: EthereumAddress, block: EthereumBlock, completionHandler: @escaping(Result<BigUInt, EthereumClientError>) -> Void)
    func eth_getCode(address: EthereumAddress, block: EthereumBlock, completionHandler: @escaping(Result<String, EthereumClientError>) -> Void)
    func eth_estimateGas(_ transaction: EthereumTransaction, completionHandler: @escaping(Result<BigUInt, EthereumClientError>) -> Void)
    func eth_sendRawTransaction(_ transaction: EthereumTransaction, withAccount account: EthereumAccountProtocol, completionHandler: @escaping(Result<String, EthereumClientError>) -> Void)
    func eth_getTransactionCount(address: EthereumAddress, block: EthereumBlock, completionHandler: @escaping(Result<Int, EthereumClientError>) -> Void)
    func eth_getTransaction(byHash txHash: String, completionHandler: @escaping(Result<EthereumTransaction, EthereumClientError>) -> Void)
    func eth_getTransactionReceipt(txHash: String, completionHandler: @escaping(Result<EthereumTransactionReceipt, EthereumClientError>) -> Void)
    func eth_call(
        _ transaction: EthereumTransaction,
        resolution: CallResolution,
        block: EthereumBlock,
        completionHandler: @escaping(Result<String, EthereumClientError>) -> Void)
    func eth_getLogs(addresses: [EthereumAddress]?, topics: [String?]?, fromBlock: EthereumBlock, toBlock: EthereumBlock, completionHandler: @escaping(Result<[EthereumLog], EthereumClientError>) -> Void)
    func eth_getLogs(addresses: [EthereumAddress]?, orTopics: [[String]?]?, fromBlock: EthereumBlock, toBlock: EthereumBlock, completionHandler: @escaping(Result<[EthereumLog], EthereumClientError>) -> Void)
    func eth_getBlockByNumber(_ block: EthereumBlock, completionHandler: @escaping(Result<EthereumBlockInfo, EthereumClientError>) -> Void)

    // Async/Await
    func net_version() async throws -> EthereumNetwork
    func eth_gasPrice() async throws -> BigUInt
    func eth_blockNumber() async throws -> Int
    func eth_getBalance(address: EthereumAddress, block: EthereumBlock) async throws -> BigUInt
    func eth_getCode(address: EthereumAddress, block: EthereumBlock) async throws -> String
    func eth_estimateGas(_ transaction: EthereumTransaction) async throws -> BigUInt
    func eth_sendRawTransaction(_ transaction: EthereumTransaction, withAccount account: EthereumAccountProtocol) async throws -> String
    func eth_getTransactionCount(address: EthereumAddress, block: EthereumBlock) async throws -> Int
    func eth_getTransaction(byHash txHash: String) async throws -> EthereumTransaction
    func eth_getTransactionReceipt(txHash: String) async throws -> EthereumTransactionReceipt
    func eth_call(
        _ transaction: EthereumTransaction,
        resolution: CallResolution,
        block: EthereumBlock
    ) async throws -> String
    func eth_getLogs(addresses: [EthereumAddress]?, topics: [String?]?, fromBlock: EthereumBlock, toBlock: EthereumBlock) async throws ->  [EthereumLog]
    func eth_getLogs(addresses: [EthereumAddress]?, orTopics: [[String]?]?, fromBlock: EthereumBlock, toBlock: EthereumBlock) async throws ->  [EthereumLog]
    func eth_getBlockByNumber(_ block: EthereumBlock) async throws -> EthereumBlockInfo

    // Deprecated
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
        self.net_version { result in
            switch result {
            case .success(let data):
                network = data
                self.retreivedNetwork = network
            case .failure(let error):
                print("Client has no network: \(error.localizedDescription)")
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

    public func net_version(completionHandler: @escaping (Result<EthereumNetwork, EthereumClientError>) -> Void) {
        let emptyParams: Array<Bool> = []
        EthereumRPC.execute(session: session, url: url, method: "net_version", params: emptyParams, receive: String.self) { result in
            switch result {
            case .success(let data):
                if let resString = data as? String {
                    let network = EthereumNetwork.fromString(resString)
                    completionHandler(.success(network))
                } else {
                    completionHandler(.failure(.unexpectedReturnValue))
                }
            case .failure(let error):
                self.failureHandler(error, completionHandler: completionHandler)
            }
        }
    }

    public func eth_gasPrice(completionHandler: @escaping (Result<BigUInt, EthereumClientError>) -> Void) {
        let emptyParams: Array<Bool> = []
        EthereumRPC.execute(session: session, url: url, method: "eth_gasPrice", params: emptyParams, receive: String.self) { result in
            switch result {
            case .success(let data):
                if let hexString = data as? String, let bigUInt = BigUInt(hex: hexString) {
                    completionHandler(.success(bigUInt))
                } else {
                    completionHandler(.failure(.unexpectedReturnValue))
                }
            case .failure(let error):
                self.failureHandler(error, completionHandler: completionHandler)
            }
        }
    }

    public func eth_blockNumber(completionHandler: @escaping (Result<Int, EthereumClientError>) -> Void) {
        let emptyParams: Array<Bool> = []
        EthereumRPC.execute(session: session, url: url, method: "eth_blockNumber", params: emptyParams, receive: String.self) { result in
            switch result {
            case .success(let data):
                if let hexString = data as? String {
                    if let integerValue = Int(hex: hexString) {
                        completionHandler(.success(integerValue))
                    } else {
                        completionHandler(.failure(.decodeIssue))
                    }
                } else {
                    completionHandler(.failure(.unexpectedReturnValue))
                }
            case .failure(let error):
                self.failureHandler(error, completionHandler: completionHandler)
            }
        }
    }

    public func eth_getBalance(address: EthereumAddress, block: EthereumBlock, completionHandler: @escaping (Result<BigUInt, EthereumClientError>) -> Void) {
        EthereumRPC.execute(session: session, url: url, method: "eth_getBalance", params: [address.value, block.stringValue], receive: String.self) { result in
            switch result {
            case .success(let data):
                if let resString = data as? String, let balanceInt = BigUInt(hex: resString.web3.noHexPrefix) {
                    completionHandler(.success(balanceInt))
                } else {
                    completionHandler(.failure(.unexpectedReturnValue))
                }
            case .failure(let error):
                self.failureHandler(error, completionHandler: completionHandler)
            }
        }
    }

    public func eth_getCode(address: EthereumAddress, block: EthereumBlock = .Latest, completionHandler: @escaping (Result<String, EthereumClientError>) -> Void) {
        EthereumRPC.execute(session: session, url: url, method: "eth_getCode", params: [address.value, block.stringValue], receive: String.self) { result in
            switch result {
            case .success(let data):
                if let resDataString = data as? String {
                    completionHandler(.success(resDataString))
                } else {
                    completionHandler(.failure(.unexpectedReturnValue))
                }
            case .failure(let error):
                self.failureHandler(error, completionHandler: completionHandler)
            }
        }
    }

    public func eth_estimateGas(_ transaction: EthereumTransaction, completionHandler: @escaping (Result<BigUInt, EthereumClientError>) -> Void) {
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

        let params = CallParams(from: transaction.from?.value,
                                to: transaction.to.value,
                                value: value?.web3.hexString,
                                data: transaction.data?.web3.hexString)
        EthereumRPC.execute(session: session, url: url, method: "eth_estimateGas", params: params, receive: String.self) { result in
            switch result {
            case .success(let data):
                if let gasHex = data as? String, let gas = BigUInt(hex: gasHex) {
                    completionHandler(.success(gas))
                } else {
                    completionHandler(.failure(.unexpectedReturnValue))
                }
            case .failure(let error):
                self.failureHandler(error, completionHandler: completionHandler)
            }
        }
    }

    public func eth_sendRawTransaction(_ transaction: EthereumTransaction, withAccount account: EthereumAccountProtocol, completionHandler: @escaping (Result<String, EthereumClientError>) -> Void) {
        concurrentQueue.addOperation {
            let group = DispatchGroup()
            group.enter()

            // Inject pending nonce
            self.eth_getTransactionCount(address: account.address, block: .Pending) { result in switch result {
            case .success(let nonce):
                var transaction = transaction
                transaction.nonce = nonce

                if transaction.chainId == nil, let network = self.network {
                    transaction.chainId = network.intValue
                }

                guard let _ = transaction.chainId, let signedTx = (try? account.sign(transaction: transaction)), let transactionHex = signedTx.raw?.web3.hexString else {
                    group.leave()
                    completionHandler(.failure(.encodeIssue))
                    return
                }

                EthereumRPC.execute(session: self.session, url: self.url, method: "eth_sendRawTransaction", params: [transactionHex], receive: String.self) { result in
                    group.leave()
                    switch result {
                    case .success(let data):
                        if let resDataString = data as? String {
                            completionHandler(.success(resDataString))
                        } else {
                            completionHandler(.failure(.unexpectedReturnValue))
                        }
                    case .failure(let error):
                        self.failureHandler(error, completionHandler: completionHandler)
                    }
                }
            case .failure(let error):
                group.leave()
                self.failureHandler(error, completionHandler: completionHandler)
            }
            }
            group.wait()
        }
    }

    public func eth_getTransactionCount(address: EthereumAddress, block: EthereumBlock, completionHandler: @escaping (Result<Int, EthereumClientError>) -> Void) {
        EthereumRPC.execute(session: session, url: url, method: "eth_getTransactionCount", params: [address.value, block.stringValue], receive: String.self) { result in
            switch result {
            case .success(let data):
                if let resString = data as? String, let count = Int(hex: resString) {
                    completionHandler(.success(count))
                } else {
                    completionHandler(.failure(.unexpectedReturnValue))
                }
            case .failure(let error):
                self.failureHandler(error, completionHandler: completionHandler)
            }
        }
    }

    public func eth_getTransaction(byHash txHash: String, completionHandler: @escaping (Result<EthereumTransaction, EthereumClientError>) -> Void) {
        EthereumRPC.execute(session: session, url: url, method: "eth_getTransactionByHash", params: [txHash], receive: EthereumTransaction.self) { result in
            switch result {
            case .success(let data):
                if let transaction = data as? EthereumTransaction {
                    completionHandler(.success(transaction))
                } else {
                    completionHandler(.failure(.unexpectedReturnValue))
                }
            case .failure(let error):
                self.failureHandler(error, completionHandler: completionHandler)
            }
        }
    }

    public func eth_getTransactionReceipt(txHash: String, completionHandler: @escaping (Result<EthereumTransactionReceipt, EthereumClientError>) -> Void) {
        EthereumRPC.execute(session: session, url: url, method: "eth_getTransactionReceipt", params: [txHash], receive: EthereumTransactionReceipt.self) { result in
            switch result {
            case .success(let data):
                if let receipt = data as? EthereumTransactionReceipt {
                    completionHandler(.success(receipt))
                } else {
                    completionHandler(.failure(.noResultFound))
                }
            case .failure(let error):
                self.failureHandler(error, completionHandler: completionHandler)
            }
        }
    }

    public func eth_getLogs(addresses: [EthereumAddress]?, topics: [String?]?, fromBlock from: EthereumBlock = .Earliest, toBlock to: EthereumBlock = .Latest, completionHandler: @escaping (Result<[EthereumLog], EthereumClientError>) -> Void) {
        eth_getLogs(addresses: addresses, topics: topics.map(Topics.plain), fromBlock: from, toBlock: to, completion: completionHandler)
    }

    public func eth_getLogs(addresses: [EthereumAddress]?, orTopics topics: [[String]?]?, fromBlock from: EthereumBlock = .Earliest, toBlock to: EthereumBlock = .Latest, completionHandler: @escaping (Result<[EthereumLog], EthereumClientError>) -> Void) {
        eth_getLogs(addresses: addresses, topics: topics.map(Topics.composed), fromBlock: from, toBlock: to, completion: completionHandler)
    }

    public func eth_getBlockByNumber(_ block: EthereumBlock, completionHandler: @escaping (Result<EthereumBlockInfo, EthereumClientError>) -> Void) {
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

        EthereumRPC.execute(session: session, url: url, method: "eth_getBlockByNumber", params: params, receive: EthereumBlockInfo.self) { result in
            switch result {
            case .success(let data):
                if let blockData = data as? EthereumBlockInfo {
                    completionHandler(.success(blockData))
                } else {
                    completionHandler(.failure(.unexpectedReturnValue))
                }
            case .failure(let error):
                self.failureHandler(error, completionHandler: completionHandler)
            }
        }
    }

    private func eth_getLogs(addresses: [EthereumAddress]?, topics: Topics?, fromBlock from: EthereumBlock, toBlock to: EthereumBlock, completion: @escaping((Result<[EthereumLog], EthereumClientError>) -> Void)) {
        DispatchQueue.global(qos: .default)
            .async {
                let result = RecursiveLogCollector(ethClient: self)
                    .getAllLogs(addresses: addresses, topics: topics, from: from, to: to)

                completion(result)
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

        EthereumRPC.execute(session: session, url: url, method: "eth_getLogs", params: [params], receive: [EthereumLog].self) { result in
            switch result {
            case .success(let data):
                if let logs = data as? [EthereumLog] {
                    completion(.success(logs))
                } else {
                    completion(.failure(.unexpectedReturnValue))
                }
            case .failure(let error):
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

    private func failureHandler<T>(_ error: Error, completionHandler: @escaping (Result<T, EthereumClientError>) -> Void) {
        if case let .executionError(result) = error as? JSONRPCError {
            completionHandler(.failure(.executionError(result.error)))
        } else {
            completionHandler(.failure(.unexpectedReturnValue))
        }
    }
}

// MARK: - Async/Await
extension EthereumClient {
    public func net_version() async throws -> EthereumNetwork {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<EthereumNetwork, Error>) in
            net_version(completionHandler: continuation.resume)
        }
    }

    public func eth_gasPrice() async throws -> BigUInt {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<BigUInt, Error>) in
            eth_gasPrice(completionHandler: continuation.resume)
        }
    }

    public func eth_blockNumber() async throws -> Int {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Int, Error>) in
            eth_blockNumber(completionHandler: continuation.resume)
        }
    }

    public func eth_getBalance(address: EthereumAddress, block: EthereumBlock) async throws -> BigUInt {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<BigUInt, Error>) in
            eth_getBalance(address: address, block: block, completionHandler: continuation.resume)
        }
    }

    public func eth_getCode(address: EthereumAddress, block: EthereumBlock = .Latest) async throws -> String {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            eth_getCode(address: address, block: block, completionHandler: continuation.resume)
        }
    }

    public func eth_estimateGas(_ transaction: EthereumTransaction) async throws -> BigUInt {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<BigUInt, Error>) in
            eth_estimateGas(transaction, completionHandler: continuation.resume)
        }
    }

    public func eth_sendRawTransaction(_ transaction: EthereumTransaction, withAccount account: EthereumAccountProtocol) async throws -> String {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            eth_sendRawTransaction(transaction, withAccount: account, completionHandler: continuation.resume)
        }
    }

    public func eth_getTransactionCount(address: EthereumAddress, block: EthereumBlock) async throws -> Int {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Int, Error>) in
            eth_getTransactionCount(address: address, block: block, completionHandler: continuation.resume)
        }
    }

    public func eth_getTransaction(byHash txHash: String) async throws -> EthereumTransaction {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<EthereumTransaction, Error>) in
            eth_getTransaction(byHash: txHash, completionHandler: continuation.resume)
        }
    }

    public func eth_getTransactionReceipt(txHash: String) async throws -> EthereumTransactionReceipt {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<EthereumTransactionReceipt, Error>) in
            eth_getTransactionReceipt(txHash: txHash, completionHandler: continuation.resume)
        }
    }

    public func eth_getLogs(addresses: [EthereumAddress]?, topics: [String?]?, fromBlock from: EthereumBlock = .Earliest, toBlock to: EthereumBlock = .Latest) async throws -> [EthereumLog] {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[EthereumLog], Error>) in
            eth_getLogs(addresses: addresses, topics: topics, fromBlock: from, toBlock: to, completionHandler: continuation.resume)
        }
    }

    public func eth_getLogs(addresses: [EthereumAddress]?, orTopics topics: [[String]?]?, fromBlock from: EthereumBlock = .Earliest, toBlock to: EthereumBlock = .Latest) async throws ->  [EthereumLog] {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[EthereumLog], Error>) in
            eth_getLogs(addresses: addresses, orTopics: topics, fromBlock: from, toBlock: to, completionHandler: continuation.resume)
        }
    }

    public func eth_getBlockByNumber(_ block: EthereumBlock) async throws -> EthereumBlockInfo {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<EthereumBlockInfo, Error>) in
            eth_getBlockByNumber(block, completionHandler: continuation.resume)
        }
    }
}

// MARK: - Deprecated
extension EthereumClient {
    @available(*, deprecated, renamed: "net_version(completionHandler:)")
    public func net_version(completion: @escaping ((EthereumClientError?, EthereumNetwork?) -> Void)) {
        net_version { result in
            switch result {
            case .success(let data):
                completion(nil, data)
            case .failure(let error):
                completion(error, nil)
            }
        }
    }

    @available(*, deprecated, renamed: "eth_gasPrice(completionHandler:)")
    public func eth_gasPrice(completion: @escaping ((EthereumClientError?, BigUInt?) -> Void)) {
        eth_gasPrice { result in
            switch result {
            case .success(let data):
                completion(nil, data)
            case .failure(let error):
                completion(error, nil)
            }
        }
    }

    @available(*, deprecated, renamed: "eth_blockNumber(completionHandler:)")
    public func eth_blockNumber(completion: @escaping ((EthereumClientError?, Int?) -> Void)) {
        eth_blockNumber { result in
            switch result {
            case .success(let data):
                completion(nil, data)
            case .failure(let error):
                completion(error, nil)
            }
        }
    }

    @available(*, deprecated, renamed: "eth_getBalance(address:block:completionHandler:)")
    public func eth_getBalance(address: EthereumAddress, block: EthereumBlock, completion: @escaping ((EthereumClientError?, BigUInt?) -> Void)) {
        eth_getBalance(address: address, block: block) { result in
            switch result {
            case .success(let data):
                completion(nil, data)
            case .failure(let error):
                completion(error, nil)
            }
        }
    }

    @available(*, deprecated, renamed: "eth_getCode(address:block:completionHandler:)")
    public func eth_getCode(address: EthereumAddress, block: EthereumBlock = .Latest, completion: @escaping((EthereumClientError?, String?) -> Void)) {
        eth_getCode(address: address, block: block) { result in
            switch result {
            case .success(let data):
                completion(nil, data)
            case .failure(let error):
                completion(error, nil)
            }
        }
    }

    @available(*, deprecated, renamed: "eth_estimateGas(_:completionHandler:)")
    public func eth_estimateGas(_ transaction: EthereumTransaction, withAccount account: EthereumAccountProtocol, completion: @escaping((EthereumClientError?, BigUInt?) -> Void)) {
        eth_estimateGas(transaction) { result in
            switch result {
            case .success(let data):
                completion(nil, data)
            case .failure(let error):
                completion(error, nil)
            }
        }
    }

    @available(*, deprecated, renamed: "eth_sendRawTransaction(_:withAccount:completionHandler:)")
    public func eth_sendRawTransaction(_ transaction: EthereumTransaction, withAccount account: EthereumAccountProtocol, completion: @escaping ((EthereumClientError?, String?) -> Void)) {
        eth_sendRawTransaction(transaction, withAccount: account) { result in
            switch result {
            case .success(let data):
                completion(nil, data)
            case .failure(let error):
                completion(error, nil)
            }
        }
    }

    @available(*, deprecated, renamed: "eth_getTransactionCount(address:block:completionHandler:)")
    public func eth_getTransactionCount(address: EthereumAddress, block: EthereumBlock, completion: @escaping ((EthereumClientError?, Int?) -> Void)) {
        eth_getTransactionCount(address: address, block: block) { result in
            switch result {
            case .success(let data):
                completion(nil, data)
            case .failure(let error):
                completion(error, nil)
            }
        }
    }

    @available(*, deprecated, renamed: "eth_getTransactionReceipt(txHash:completionHandler:)")
    public func eth_getTransactionReceipt(txHash: String, completion: @escaping ((EthereumClientError?, EthereumTransactionReceipt?) -> Void)) {
        eth_getTransactionReceipt(txHash: txHash) { result in
            switch result {
            case .success(let data):
                completion(nil, data)
            case .failure(let error):
                completion(error, nil)
            }
        }
    }

    @available(*, deprecated, renamed: "eth_getTransaction(byHash:completionHandler:)")
    public func eth_getTransaction(byHash txHash: String, completion: @escaping((EthereumClientError?, EthereumTransaction?) -> Void)) {
        eth_getTransaction(byHash: txHash) { result in
            switch result {
            case .success(let data):
                completion(nil, data)
            case .failure(let error):
                completion(error, nil)
            }
        }
    }

    @available(*, deprecated, renamed: "eth_getLogs(addresses:topics:fromBlock:toBlock:completionHandler:)")
    public func eth_getLogs(addresses: [EthereumAddress]?, topics: [String?]?, fromBlock from: EthereumBlock = .Earliest, toBlock to: EthereumBlock = .Latest, completion: @escaping ((EthereumClientError?, [EthereumLog]?) -> Void)) {
        eth_getLogs(addresses: addresses, topics: topics) { result in
            switch result {
            case .success(let data):
                completion(nil, data)
            case .failure(let error):
                completion(error, nil)
            }
        }
    }

    @available(*, deprecated, renamed: "eth_getLogs(addresses:orTopics:fromBlock:toBlock:completionHandler:)")
    public func eth_getLogs(addresses: [EthereumAddress]?, orTopics topics: [[String]?]?, fromBlock from: EthereumBlock = .Earliest, toBlock to: EthereumBlock = .Latest, completion: @escaping((EthereumClientError?, [EthereumLog]?) -> Void)) {
        eth_getLogs(addresses: addresses, orTopics: topics) { result in
            switch result {
            case .success(let data):
                completion(nil, data)
            case .failure(let error):
                completion(error, nil)
            }
        }
    }

    @available(*, deprecated, renamed: "eth_getBlockByNumber(_:completionHandler:)")
    public func eth_getBlockByNumber(_ block: EthereumBlock, completion: @escaping((EthereumClientError?, EthereumBlockInfo?) -> Void)) {
        eth_getBlockByNumber(block) { result in
            switch result {
            case .success(let data):
                completion(nil, data)
            case .failure(let error):
                completion(error, nil)
            }
        }
    }
}
