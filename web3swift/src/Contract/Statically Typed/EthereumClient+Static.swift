//
//  EthereumClient+Static.swift
//  web3swift
//
//  Created by Matt Marshall on 10/04/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation

public extension ABIFunction {
    func execute(withClient client: EthereumClient, account: EthereumAccount, completion: @escaping((EthereumClientError?, String?) -> Void)) {
        
        guard let tx = try? self.transaction() else {
            return completion(EthereumClientError.encodeIssue, nil)
        }
        
        
        client.eth_sendRawTransaction(tx, withAccount: account) { (error, res) in
            guard let res = res, error == nil else {
                return completion(EthereumClientError.unexpectedReturnValue, nil)
            }
            
            return completion(nil, res)
        }
        
    }
    
    func call<T: ABIResponse>(withClient client: EthereumClient, responseType: T.Type, completion: @escaping((EthereumClientError?, T?) -> Void)) {
        
        guard let tx = try? self.transaction() else {
            return completion(EthereumClientError.encodeIssue, nil)
        }
        
        client.eth_call(tx) { (error, res) in
            guard let res = res, error == nil else {
                return completion(EthereumClientError.unexpectedReturnValue, nil)
            }
            
            guard let response = (try? T(data: res)) as? T else {
                return completion(EthereumClientError.decodeIssue, nil)
            }
            
            return completion(nil, response)
        }
    }
}

public extension EthereumClient {
    func getEvents(addresses: [String]?, topics: [String?]?, fromBlock: EthereumBlock, toBlock: EthereumBlock, eventTypes: [ABIEvent.Type], completion: @escaping((EthereumClientError?, [ABIEvent], [EthereumLog]) -> Void)) {
        
        self.eth_getLogs(addresses: addresses, topics: topics, fromBlock: fromBlock, toBlock: toBlock) { (error, logs) in
            
            if let error = error {
                return completion(error, [], [])
            }
            
            guard let logs = logs else { return completion(nil, [], []) }
            
            var events: [ABIEvent] = []
            var unprocessed: [EthereumLog] = []
            
            var eventTypesBySignature: [String: ABIEvent.Type] = [:]
            for eventType in eventTypes {
                if let sig = try? eventType.signature() {
                    eventTypesBySignature[sig] = eventType
                }
            }
            
            for log in logs {
                
                guard let signature = log.topics.first, let eventType = eventTypesBySignature[signature] else {
                    unprocessed.append(log)
                    continue
                }
                let topicTypes = eventType.types.enumerated()
                    .filter { eventType.typesIndexed[$0.offset] == true }
                    .compactMap { $0.element }
                
                let dataTypes = eventType.types.enumerated()
                    .filter { eventType.typesIndexed[$0.offset] == false }
                    .compactMap { $0.element }
                
                guard let data = try? ABIDecoder.decodeData(log.data, types: dataTypes) else {
                    unprocessed.append(log)
                    continue
                }
                
                guard data.count == dataTypes.count else {
                    unprocessed.append(log)
                    continue
                }
                
                let rawTopics = Array(log.topics.dropFirst())
                    
                guard let parsedTopics = (try? zip(rawTopics, topicTypes).map { pair in
                    try ABIDecoder.decodeData(pair.0, types: [pair.1])
                    }) else {
                        unprocessed.append(log)
                        continue
                }
                
                guard let eventOpt = try? eventType.init(topics: parsedTopics.flatMap { $0 }, data: data, log: log), let event = eventOpt else {
                        unprocessed.append(log)
                    continue
                }
                
                events.append(event)
            }
            
            return completion(error, events, unprocessed)
        }
        
    }
}
