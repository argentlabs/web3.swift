//
//  EthereumClient.swift
//  web3swift
//
//  Created by Julien Niset on 15/02/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation
import BigInt

public protocol EthereumClientProtocol {
    init(url: URL, sessionConfig: URLSessionConfiguration)
    init(url: URL)
    var network: EthereumNetwork? { get }
    
    func net_version(completion: @escaping((EthereumClientError?, EthereumNetwork?) -> Void))
    func eth_gasPrice(completion: @escaping((EthereumClientError?, BigUInt?) -> Void))
    func eth_blockNumber(completion: @escaping((EthereumClientError?, Int?) -> Void))
    func eth_getBalance(address: EthereumAddress, block: EthereumBlock, completion: @escaping((EthereumClientError?, BigUInt?) -> Void))
    func eth_getCode(address: EthereumAddress, block: EthereumBlock, completion: @escaping((EthereumClientError?, String?) -> Void))
    func eth_estimateGas(_ transaction: EthereumTransaction, withAccount account: EthereumAccount, completion: @escaping((EthereumClientError?, BigUInt?) -> Void))
    func eth_sendRawTransaction(_ transaction: EthereumTransaction, withAccount account: EthereumAccount, completion: @escaping((EthereumClientError?, String?) -> Void))
    func eth_getTransactionCount(address: EthereumAddress, block: EthereumBlock, completion: @escaping((EthereumClientError?, Int?) -> Void))
    func eth_getTransaction(byHash txHash: String, completion: @escaping((EthereumClientError?, EthereumTransaction?) -> Void))
    func eth_getTransactionReceipt(txHash: String, completion: @escaping((EthereumClientError?, EthereumTransactionReceipt?) -> Void))
    func eth_call(_ transaction: EthereumTransaction, block: EthereumBlock, completion: @escaping((EthereumClientError?, String?) -> Void))
    func eth_getLogs(addresses: [EthereumAddress]?, topics: [String?]?, fromBlock: EthereumBlock, toBlock: EthereumBlock, completion: @escaping((EthereumClientError?, [EthereumLog]?) -> Void))
    func eth_getLogs(addresses: [EthereumAddress]?, orTopics: [[String]?]?, fromBlock: EthereumBlock, toBlock: EthereumBlock, completion: @escaping((EthereumClientError?, [EthereumLog]?) -> Void))
    func eth_getBlockByNumber(_ block: EthereumBlock, completion: @escaping((EthereumClientError?, EthereumBlockInfo?) -> Void))
}

public enum EthereumClientError: Error {
    case tooManyResults
    case executionError
    case unexpectedReturnValue
    case noResult
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
    
    @available(*, deprecated, message: "Prefer async alternative instead")
    public func net_version(completion: @escaping ((EthereumClientError?, EthereumNetwork?) -> Void)) {
        async {
            do {
                let result = try await net_version()
                completion(nil, result)
            } catch {
                completion(error as? EthereumClientError, nil)
            }
        }
    }
    
    public func net_version() async throws -> EthereumNetwork {
        let emptyParams: Array<Bool> = []
        let response = try await EthereumRPC.execute(session: session, url: url, method: "net_version", params: emptyParams, receive: String.self)
        guard let resString = response as? String else {
            throw EthereumClientError.unexpectedReturnValue
        }
        return EthereumNetwork.fromString(resString)
    }
    
    @available(*, deprecated, message: "Prefer async alternative instead")
    public func eth_gasPrice(completion: @escaping ((EthereumClientError?, BigUInt?) -> Void)) {
        async {
            do {
                let result = try await eth_gasPrice()
                completion(nil, result)
            } catch {
                completion(error as? EthereumClientError, nil)
            }
        }
    }
    
    public func eth_gasPrice() async throws -> BigUInt {
        let emptyParams: Array<Bool> = []
        let response = try await EthereumRPC.execute(session: session, url: url, method: "eth_gasPrice", params: emptyParams, receive: String.self)
        guard let hexString = response as? String, let gasPrice = BigUInt(hex: hexString) else {
            throw EthereumClientError.unexpectedReturnValue
        }
        return gasPrice
    }
    
    @available(*, deprecated, message: "Prefer async alternative instead")
    public func eth_blockNumber(completion: @escaping ((EthereumClientError?, Int?) -> Void)) {
        async {
            do {
                let result = try await eth_blockNumber()
                completion(nil, result)
            } catch {
                completion(error as? EthereumClientError, nil)
            }
        }
    }
    
    public func eth_blockNumber() async throws -> Int {
        let emptyParams: Array<Bool> = []
        let response = try await EthereumRPC.execute(session: session, url: url, method: "eth_blockNumber", params: emptyParams, receive: String.self)
        guard let hexString = response as? String else {
            throw EthereumClientError.unexpectedReturnValue
        }
        guard let integerValue = Int(hex: hexString) else {
            throw EthereumClientError.decodeIssue
        }
        return integerValue
    }
    
    @available(*, deprecated, message: "Prefer async alternative instead")
    public func eth_getBalance(address: EthereumAddress, block: EthereumBlock = .latest, completion: @escaping ((EthereumClientError?, BigUInt?) -> Void)) {
        async {
            do {
                let result = try await eth_getBalance(address: address, block: block)
                completion(nil, result)
            } catch {
                completion(error as? EthereumClientError, nil)
            }
        }
    }
        
    public func eth_getBalance(address: EthereumAddress, block: EthereumBlock = .latest) async throws -> BigUInt {
        let response = try await EthereumRPC.execute(session: session, url: url, method: "eth_getBalance", params: [address.value, block.stringValue], receive: String.self)
        guard let resString = response as? String, let balanceInt = BigUInt(hex: resString.web3.noHexPrefix) else {
            throw EthereumClientError.unexpectedReturnValue
        }
        return balanceInt
    }
    
    @available(*, deprecated, message: "Prefer async alternative instead")
    public func eth_getCode(address: EthereumAddress, block: EthereumBlock = .latest, completion: @escaping((EthereumClientError?, String?) -> Void)) {
        async {
            do {
                let result = try await eth_getCode(address: address, block: block)
                completion(nil, result)
            } catch {
                completion(error as? EthereumClientError, nil)
            }
        }
    }
        
    public func eth_getCode(address: EthereumAddress, block: EthereumBlock = .latest) async throws -> String {
        let response = try await EthereumRPC.execute(session: session, url: url, method: "eth_getCode", params: [address.value, block.stringValue], receive: String.self)
        guard let resDataString = response as? String else {
            throw EthereumClientError.unexpectedReturnValue
        }
        return resDataString
    }
    
    @available(*, deprecated, message: "Prefer async alternative instead")
    public func eth_estimateGas(_ transaction: EthereumTransaction, withAccount account: EthereumAccount, completion: @escaping((EthereumClientError?, BigUInt?) -> Void)) {
        async {
            do {
                let result = try await eth_estimateGas(transaction, withAccount: account)
                completion(nil, result)
            } catch {
                completion(error as? EthereumClientError, nil)
            }
        }
    }
    
    public func eth_estimateGas(_ transaction: EthereumTransaction, withAccount account: EthereumAccount) async throws -> BigUInt {
        
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
        
        let value1: BigUInt?
        if let txValue = transaction.value, txValue > .zero {
            value1 = txValue
        } else {
            value1 = nil
        }
        
        let params = CallParams(from: transaction.from?.value,
                                to: transaction.to.value,
                                gas: transaction.gasLimit?.web3.hexString,
                                gasPrice: transaction.gasPrice?.web3.hexString,
                                value: value1?.web3.hexString,
                                data: transaction.data?.web3.hexString)
        do {
            let response = try await EthereumRPC.execute(session: session, url: url, method: "eth_estimateGas", params: params, receive: String.self)
        
            guard let gasHex = response as? String, let gas = BigUInt(hex: gasHex) else {
               throw EthereumClientError.unexpectedReturnValue
            }
            return gas
        } catch {
            if let error = error as? JSONRPCError, error.isExecutionError {
               throw EthereumClientError.executionError
           } else {
               throw EthereumClientError.unexpectedReturnValue
           }
        }
    }
    
    @available(*, deprecated, message: "Prefer async alternative instead")
    public func eth_sendRawTransaction(_ transaction: EthereumTransaction, withAccount account: EthereumAccount, completion: @escaping ((EthereumClientError?, String?) -> Void)) {
        async {
            do {
                let result = try await eth_sendRawTransaction(transaction, withAccount: account)
                completion(nil, result)
            } catch {
                completion(error as? EthereumClientError, nil)
            }
        }
    }
    
    
    public func eth_sendRawTransaction(_ transaction: EthereumTransaction, withAccount account: EthereumAccount) async throws -> String {
        
        // Inject pending nonce
        let nonce = try await eth_getTransactionCount(address: account.address, block: .pending)
        
        var transaction1 = transaction
        transaction1.nonce = nonce
        
        if transaction1.chainId == nil, let network = self.network {
            transaction1.chainId = network.intValue
        }
        
        guard let _ = transaction1.chainId, let signedTx = (try? account.sign(transaction: transaction1)), let transactionHex = signedTx.raw?.web3.hexString else {
            throw EthereumClientError.encodeIssue
        }
        
        let response = try await EthereumRPC.execute(session: self.session, url: self.url, method: "eth_sendRawTransaction", params: [transactionHex], receive: String.self)
        
        guard let resDataString = response as? String else {
            throw EthereumClientError.unexpectedReturnValue
        }
        return resDataString
    }
    
    @available(*, deprecated, message: "Prefer async alternative instead")
    public func eth_getTransactionCount(address: EthereumAddress, block: EthereumBlock, completion: @escaping ((EthereumClientError?, Int?) -> Void)) {
        async {
            do {
                let result = try await eth_getTransactionCount(address: address, block: block)
                completion(nil, result)
            } catch {
                completion(error as? EthereumClientError, nil)
            }
        }
    }
    
    public func eth_getTransactionCount(address: EthereumAddress, block: EthereumBlock) async throws -> Int {
        let response = try await EthereumRPC.execute(session: session, url: url, method: "eth_getTransactionCount", params: [address.value, block.stringValue], receive: String.self)
        guard let resString = response as? String, let count = Int(hex: resString) else {
            throw EthereumClientError.unexpectedReturnValue
        }
        return count
    }
    
    @available(*, deprecated, message: "Prefer async alternative instead")
    public func eth_getTransactionReceipt(txHash: String, completion: @escaping ((EthereumClientError?, EthereumTransactionReceipt?) -> Void)) {
        async {
            do {
                let result = try await eth_getTransactionReceipt(txHash: txHash)
                completion(nil, result)
            } catch {
                completion(error as? EthereumClientError, nil)
            }
        }
    }
        
    // FIXME: try throws JSONRPCError instead of EthereumClientError.
    public func eth_getTransactionReceipt(txHash: String) async throws -> EthereumTransactionReceipt {
        let response = try await EthereumRPC.execute(session: session, url: url, method: "eth_getTransactionReceipt", params: [txHash], receive: EthereumTransactionReceipt.self)
        guard let receipt = response as? EthereumTransactionReceipt else {
            throw EthereumClientError.noResult
        }
        return receipt
    }
    
    @available(*, deprecated, message: "Prefer async alternative instead")
    public func eth_getTransaction(byHash txHash: String, completion: @escaping((EthereumClientError?, EthereumTransaction?) -> Void)) {
        async {
            do {
                let result = try await eth_getTransaction(byHash: txHash)
                completion(nil, result)
            } catch {
                completion(error as? EthereumClientError, nil)
            }
        }
    }
    
    public func eth_getTransaction(byHash txHash: String) async throws -> EthereumTransaction {
        
        let response = try await EthereumRPC.execute(session: session, url: url, method: "eth_getTransactionByHash", params: [txHash], receive: EthereumTransaction.self)
        guard let transaction = response as? EthereumTransaction else {
            throw EthereumClientError.unexpectedReturnValue
        }
        return transaction
    }
    
    @available(*, deprecated, message: "Prefer async alternative instead")
    public func eth_call(_ transaction: EthereumTransaction, block: EthereumBlock = .latest, completion: @escaping ((EthereumClientError?, String?) -> Void)) {
        async {
            do {
                let result = try await eth_call(transaction, block: block)
                completion(nil, result)
            } catch {
                completion(error as? EthereumClientError, nil)
            }
        }
    }
    
    
    public func eth_call(_ transaction: EthereumTransaction, block: EthereumBlock = .latest) async throws -> String {
        guard let transactionData = transaction.data else {
            throw EthereumClientError.noInputData
        }
        
        struct CallParams: Encodable {
            let from: String?
            let to: String
            let data: String
            let block: String
            
            enum TransactionCodingKeys: String, CodingKey {
                case from
                case to
                case data
            }
            
            func encode(to encoder: Encoder) throws {
                var container = encoder.unkeyedContainer()
                var nested = container.nestedContainer(keyedBy: TransactionCodingKeys.self)
                if let from = from {
                    try nested.encode(from, forKey: .from)
                }
                try nested.encode(to, forKey: .to)
                try nested.encode(data, forKey: .data)
                try container.encode(block)
            }
        }
        
        let params = CallParams(from: transaction.from?.value, to: transaction.to.value, data: transactionData.web3.hexString, block: block.stringValue)
        do {
            let response = try await EthereumRPC.execute(session: session, url: url, method: "eth_call", params: params, receive: String.self)
            guard let resDataString = response as? String else {
                throw EthereumClientError.unexpectedReturnValue
            }
            return resDataString
        } catch {
            if case let JSONRPCError.executionError(result) = error,
                (result.error.code == JSONRPCErrorCode.invalidInput || result.error.code == JSONRPCErrorCode.contractExecution) {
                return "0x"
            } else {
                throw EthereumClientError.unexpectedReturnValue
            }
        }
    }
    
    @available(*, deprecated, message: "Prefer async alternative instead")
    public func eth_getLogs(addresses: [EthereumAddress]?, topics: [String?]?, fromBlock from: EthereumBlock = .earliest, toBlock to: EthereumBlock = .latest, completion: @escaping ((EthereumClientError?, [EthereumLog]?) -> Void)) {
        async {
            do {
                let result = try await eth_getLogs(addresses: addresses, topics: topics, fromBlock: from, toBlock: to)
                completion(nil, result)
            } catch {
                completion(error as? EthereumClientError, nil)
            }
        }
    }
    
    public func eth_getLogs(addresses: [EthereumAddress]?, topics: [String?]?, fromBlock from: EthereumBlock = .earliest, toBlock to: EthereumBlock = .latest) async throws -> [EthereumLog] {
        return try await eth_getLogs(addresses: addresses, topics: topics.map(Topics.plain), fromBlock: from, toBlock: to)
    }
    
    @available(*, deprecated, message: "Prefer async alternative instead")
    public func eth_getLogs(addresses: [EthereumAddress]?, orTopics topics: [[String]?]?, fromBlock from: EthereumBlock = .earliest, toBlock to: EthereumBlock = .latest, completion: @escaping((EthereumClientError?, [EthereumLog]?) -> Void)) {
        async {
            do {
                let result = try await eth_getLogs(addresses: addresses, orTopics: topics, fromBlock: from, toBlock: to)
                completion(nil, result)
            } catch {
                completion(error as? EthereumClientError, nil)
            }
        }
    }
    
    
    public func eth_getLogs(addresses: [EthereumAddress]?, orTopics topics: [[String]?]?, fromBlock from: EthereumBlock = .earliest, toBlock to: EthereumBlock = .latest) async throws -> [EthereumLog] {
        return try await eth_getLogs(addresses: addresses, topics: topics.map(Topics.composed), fromBlock: from, toBlock: to)
    }

    @available(*, deprecated, message: "Prefer async alternative instead")
    private func eth_getLogs(addresses: [EthereumAddress]?, topics: Topics?, fromBlock from: EthereumBlock, toBlock to: EthereumBlock, completion: @escaping((EthereumClientError?, [EthereumLog]?) -> Void)) {
        async {
            do {
                let result = try await eth_getLogs(addresses: addresses, topics: topics, fromBlock: from, toBlock: to)
                completion(nil, result)
            } catch {
                completion(error as? EthereumClientError, nil)
            }
        }
    }
    
    
    private func eth_getLogs(addresses: [EthereumAddress]?, topics: Topics?, fromBlock from: EthereumBlock, toBlock to: EthereumBlock) async throws -> [EthereumLog] {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .default)
                .async {
                    let result = RecursiveLogCollector(ethClient: self)
                        .getAllLogs(addresses: addresses, topics: topics, from: from, to: to)
                    
                    switch result {
                    case .success(let logs):
                        continuation.resume(returning: logs)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
        }
    }

    @available(*, deprecated, message: "Prefer async alternative instead")
    internal func getLogs(addresses: [EthereumAddress]?, topics: Topics?, fromBlock: EthereumBlock, toBlock: EthereumBlock, completion: @escaping((Result<[EthereumLog], EthereumClientError>) -> Void)) {
        async {
            do {
                let result = try await getLogs(addresses: addresses, topics: topics, fromBlock: fromBlock, toBlock: toBlock)
                completion(.success(result))
            } catch {
                completion(.failure(error as! EthereumClientError))
            }
        }
    }
    
    
    internal func getLogs(addresses: [EthereumAddress]?, topics: Topics?, fromBlock: EthereumBlock, toBlock: EthereumBlock) async throws -> [EthereumLog] {
        
        struct CallParams: Encodable {
            var fromBlock: String
            var toBlock: String
            let address: [EthereumAddress]?
            let topics: Topics?
        }
        
        let params = CallParams(fromBlock: fromBlock.stringValue, toBlock: toBlock.stringValue, address: addresses, topics: topics)
        
        do {
            let response = try await EthereumRPC.execute(session: session, url: url, method: "eth_getLogs", params: [params], receive: [EthereumLog].self)
            guard let logs = response as? [EthereumLog] else {
                throw EthereumClientError.unexpectedReturnValue
            }
            return logs
        } catch {
            if let error = error as? JSONRPCError,
               case let JSONRPCError.executionError(innerError) = error,
               innerError.error.code == JSONRPCErrorCode.tooManyResults {
                throw EthereumClientError.tooManyResults
            } else {
                throw EthereumClientError.unexpectedReturnValue
            }
        }
    }

    @available(*, deprecated, message: "Prefer async alternative instead")
    public func eth_getBlockByNumber(_ block: EthereumBlock, completion: @escaping((EthereumClientError?, EthereumBlockInfo?) -> Void)) {
        async {
            do {
                let result = try await eth_getBlockByNumber(block)
                completion(nil, result)
            } catch {
                completion(error as? EthereumClientError, nil)
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
            let response = try await EthereumRPC.execute(session: session, url: url, method: "eth_getBlockByNumber", params: params, receive: EthereumBlockInfo.self)
            guard let blockData = response as? EthereumBlockInfo else {
                throw EthereumClientError.unexpectedReturnValue
            }
            return blockData
        } catch {
            throw EthereumClientError.unexpectedReturnValue
        }        
    }
}

