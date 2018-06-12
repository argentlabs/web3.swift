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
    func eth_getBalance(address: String, block: EthereumBlock, completion: @escaping((EthereumClientError?, BigUInt?) -> Void))
    func eth_getCode(address: String, block: EthereumBlock, completion: @escaping((EthereumClientError?, String?) -> Void))
    func eth_sendRawTransaction(_ transaction: EthereumTransaction, withAccount account: EthereumAccount, completion: @escaping((EthereumClientError?, String?) -> Void))
    func eth_getTransactionCount(address: String, block: EthereumBlock, completion: @escaping((EthereumClientError?, Int?) -> Void))
    func eth_getTransactionReceipt(txHash: String, completion: @escaping((EthereumClientError?, EthereumTransactionReceipt?) -> Void))
    func eth_call(_ transaction: EthereumTransaction, block: EthereumBlock, completion: @escaping((EthereumClientError?, String?) -> Void))
    func eth_getLogs(addresses: [String]?, topics: [String?]?, fromBlock: EthereumBlock, toBlock: EthereumBlock, completion: @escaping((EthereumClientError?, [EthereumLog]?) -> Void))
    func eth_getBlockByNumber(_ block: EthereumBlock, completion: @escaping((EthereumClientError?, EthereumBlockInfo?) -> Void))
}

public enum EthereumClientError: Error {
    case unexpectedReturnValue
    case noResultFound
    case decodeIssue
    case encodeIssue
    case noInputData
}

public class EthereumClient: EthereumClientProtocol {
    public let url: URL
    private let sessionConfig: URLSessionConfiguration
    private var retreivedNetwork: EthereumNetwork?

    private lazy var networkQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "web3swift.client.networkQueue"
        queue.qualityOfService = .background
        queue.maxConcurrentOperationCount = 4
        return queue
    }()
    
    private lazy var concurrentQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "web3swift.client.rawTxQueue"
        queue.qualityOfService = .background
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    public lazy var session: URLSession = {
        return URLSession(configuration: self.sessionConfig, delegate: nil, delegateQueue: self.networkQueue)
    }()
    
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
            }
            network = retreivedNetwork
            group.leave()
        }
        
        group.wait()
        return network
    }
    
    required public init(url: URL, sessionConfig: URLSessionConfiguration) {
        self.url = url
        self.sessionConfig = sessionConfig
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
    
    public func eth_getBalance(address: String, block: EthereumBlock, completion: @escaping ((EthereumClientError?, BigUInt?) -> Void)) {
        EthereumRPC.execute(session: session, url: url, method: "eth_getBalance", params: [address, block.stringValue], receive: String.self) { (error, response) in
            if let resString = response as? String, let balanceInt = BigUInt(hex: resString.noHexPrefix) {
                completion(nil, balanceInt)
            } else {
                completion(EthereumClientError.unexpectedReturnValue, nil)
            }
        }
    }
    
    public func eth_getCode(address: String, block: EthereumBlock = .Latest, completion: @escaping((EthereumClientError?, String?) -> Void)) {
        EthereumRPC.execute(session: session, url: url, method: "eth_getCode", params: [address, block.stringValue], receive: String.self) { (error, response) in
            if let resDataString = response as? String {
                completion(nil, resDataString)
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
                
                guard let _ = transaction.chainId, let signedTx = (try? account.sign(transaction)), let transactionHex = signedTx.raw?.hexString else {
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
    
    public func eth_getTransactionCount(address: String, block: EthereumBlock, completion: @escaping ((EthereumClientError?, Int?) -> Void)) {
        EthereumRPC.execute(session: session, url: url, method: "eth_getTransactionCount", params: [address, block.stringValue], receive: String.self) { (error, response) in
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
        
        let params = CallParams(from: transaction.from, to: transaction.to, data: transactionData.hexString, block: block.stringValue)
        EthereumRPC.execute(session: session, url: url, method: "eth_call", params: params, receive: String.self) { (error, response) in
            if let resDataString = response as? String {
                completion(nil, resDataString)
            } else {
                completion(EthereumClientError.unexpectedReturnValue, nil)
            }
        }
    }
    
    public func eth_getLogs(addresses: [String]?, topics: [String?]?, fromBlock: EthereumBlock = .Earliest, toBlock: EthereumBlock = .Latest, completion: @escaping ((EthereumClientError?, [EthereumLog]?) -> Void)) {
        
        struct CallParams: Encodable {
            let fromBlock: String
            let toBlock: String
            let address: [String]?
            let topics: [String?]?
        }
        
        let params = CallParams(fromBlock: fromBlock.stringValue, toBlock: toBlock.stringValue, address: addresses, topics: topics)
        
        EthereumRPC.execute(session: session, url: url, method: "eth_getLogs", params: [params], receive: [EthereumLog].self) { (error, response) in
            if let log = response as? [EthereumLog] {
                completion(nil, log)
            } else {
                completion(EthereumClientError.unexpectedReturnValue, nil)
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

