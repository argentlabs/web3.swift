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
    
    public func eth_estimateGas(_ transaction: EthereumTransaction, withAccount account: EthereumAccount, completion: @escaping((EthereumClientError?, BigUInt?) -> Void)) {
        
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
            } else if let error = error as? JSONRPCError, error.isExecutionError {
                completion(EthereumClientError.executionError, nil)
            } else {
                completion(EthereumClientError.unexpectedReturnValue, nil)
            }
        }
    }
    
    public func eth_sendRawTransaction(_ transaction: EthereumTransaction, withAccount account: EthereumAccount, completion: @escaping ((EthereumClientError?, String?) -> Void)) {
        
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
    
    public func eth_call(_ transaction: EthereumTransaction, block: EthereumBlock = .Latest, completion: @escaping ((EthereumClientError?, String?) -> Void)) {
        guard let transactionData = transaction.data else {
            return completion(EthereumClientError.noInputData, nil)
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
        EthereumRPC.execute(session: session, url: url, method: "eth_call", params: params, receive: String.self) { (error, response) in
            if let resDataString = response as? String {
                completion(nil, resDataString)
            } else if
                let error = error,
                case let JSONRPCError.executionError(result) = error,
                (result.error.code == JSONRPCErrorCode.invalidInput || result.error.code == JSONRPCErrorCode.contractExecution) {
                completion(nil, "0x")
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

