//
//  EthereumClient+Static.swift
//  web3swift
//
//  Created by Matt Marshall on 10/04/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation

public extension ABIFunction {
    func execute(withClient client: EthereumClientProtocol, account: EthereumAccount, completion: @escaping((EthereumClientError?, String?) -> Void)) {
        
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
    
    @available(*, deprecated, message: "Prefer async alternative instead")
    func call<T: ABIResponse>(withClient client: EthereumClientProtocol, responseType: T.Type, block: EthereumBlock = .latest, completion: @escaping((EthereumClientError?, T?) -> Void)) {
        async {
            do {
                let result: T = try await call(withClient: client, responseType: responseType, block: block)
                completion(nil, result)
            } catch {
                completion(error as? EthereumClientError, nil)
            }
        }
    }
    
    
    func call<T: ABIResponse>(withClient client: EthereumClientProtocol, responseType: T.Type, block: EthereumBlock = .latest) async throws -> T {
        
        guard let tx = try? self.transaction() else {
            throw EthereumClientError.encodeIssue
        }
        
        let res = try await client.eth_call(tx, block: block)
        guard let response = (try? T(data: res)) else {
            throw EthereumClientError.decodeIssue
        }
        
        return response
//        return continuation.resume(returning: (nil, response))
//
//
//        return await withCheckedContinuation { continuation in
//            client.eth_call(tx, block: block) { (error, res) in
//                guard let res1 = res, error == nil else {
//                    return continuation.resume(returning: (EthereumClientError.unexpectedReturnValue, nil))
//                }
//
//                guard let response = (try? T(data: res1)) else {
//                    return continuation.resume(returning: (EthereumClientError.decodeIssue, nil))
//                }
//
//                return continuation.resume(returning: (nil, response))
//            }
//        }
    }
}

public struct EventFilter {
    public let type: ABIEvent.Type
    public let allowedSenders: [EthereumAddress]
    
    public init(type: ABIEvent.Type,
                allowedSenders: [EthereumAddress]) {
        self.type = type
        self.allowedSenders = allowedSenders
    }
}

public extension EthereumClient {
    
    typealias EventsCompletion = (EthereumClientError?, [ABIEvent], [EthereumLog]) -> Void
    
    @available(*, deprecated, message: "Prefer async alternative instead")
    func getEvents(addresses: [EthereumAddress]?,
                   orTopics: [[String]?]?,
                   fromBlock: EthereumBlock,
                   toBlock: EthereumBlock,
                   matching matches: [EventFilter],
                   completion: @escaping EventsCompletion) {
        async {
            do {
            let result = try await getEvents(addresses: addresses, orTopics: orTopics, fromBlock: fromBlock, toBlock: toBlock, matching: matches)
                completion(nil, result.0, result.1)
            } catch {
                completion(error as? EthereumClientError, [], [])
            }
        }
    }
    
    
    func getEvents(addresses: [EthereumAddress]?,
                   orTopics: [[String]?]?,
                   fromBlock: EthereumBlock,
                   toBlock: EthereumBlock,
                   matching matches: [EventFilter]) async throws -> ([ABIEvent], [EthereumLog]) {
        
        let logs = try await self.eth_getLogs(addresses: addresses, orTopics: orTopics, fromBlock: fromBlock, toBlock: toBlock)
        return try await self.handleLogs(logs, matches)
    }
    
    @available(*, deprecated, message: "Prefer async alternative instead")
    func getEvents(addresses: [EthereumAddress]?,
                   orTopics: [[String]?]?,
                   fromBlock: EthereumBlock,
                   toBlock: EthereumBlock,
                   eventTypes: [ABIEvent.Type],
                   completion: @escaping EventsCompletion) {
        async {
            do {
                let result = try await getEvents(addresses: addresses, orTopics: orTopics, fromBlock: fromBlock, toBlock: toBlock, eventTypes: eventTypes)
                completion(nil, result.0, result.1)
            } catch {
                completion(error as? EthereumClientError, [], [])
            }
        }
    }
    
    
    func getEvents(addresses: [EthereumAddress]?,
                   orTopics: [[String]?]?,
                   fromBlock: EthereumBlock,
                   toBlock: EthereumBlock,
                   eventTypes: [ABIEvent.Type]) async throws -> ([ABIEvent], [EthereumLog]) {
        let unfiltered = eventTypes.map { EventFilter(type: $0, allowedSenders: []) }
        let logs = try await self.eth_getLogs(addresses: addresses, orTopics: orTopics, fromBlock: fromBlock, toBlock: toBlock)
        return try await self.handleLogs(logs, unfiltered)
    }

    @available(*, deprecated, message: "Prefer async alternative instead")
    func getEvents(addresses: [EthereumAddress]?,
                   topics: [String?]?,
                   fromBlock: EthereumBlock,
                   toBlock: EthereumBlock,
                   eventTypes: [ABIEvent.Type],
                   completion: @escaping EventsCompletion) {
        async {
            do {
                let result = try await getEvents(addresses: addresses, topics: topics, fromBlock: fromBlock, toBlock: toBlock, eventTypes: eventTypes)
                completion(nil, result.0, result.1)
            } catch {
                completion(error as? EthereumClientError, [], [])
            }
        }
    }
    
    func getEvents(addresses: [EthereumAddress]?,
                   topics: [String?]?,
                   fromBlock: EthereumBlock,
                   toBlock: EthereumBlock,
                   eventTypes: [ABIEvent.Type]) async throws -> ([ABIEvent], [EthereumLog]) {
        let unfiltered = eventTypes.map { EventFilter(type: $0, allowedSenders: []) }
        return try await getEvents(addresses: addresses, topics: topics, fromBlock: fromBlock, toBlock: toBlock, matching: unfiltered)
    }
    
    @available(*, deprecated, message: "Prefer async alternative instead")
    func getEvents(addresses: [EthereumAddress]?,
                   topics: [String?]?,
                   fromBlock: EthereumBlock,
                   toBlock: EthereumBlock,
                   matching matches: [EventFilter],
                   completion: @escaping EventsCompletion) {
        async {
            do {
                let result = try await getEvents(addresses: addresses, topics: topics, fromBlock: fromBlock, toBlock: toBlock, matching: matches)
                completion(nil, result.0, result.1)
            } catch {
                completion(error as? EthereumClientError, [], [])
            }
        }
    }
    
    func getEvents(addresses: [EthereumAddress]?,
                   topics: [String?]?,
                   fromBlock: EthereumBlock,
                   toBlock: EthereumBlock,
                   matching matches: [EventFilter]) async throws -> ([ABIEvent], [EthereumLog]) {
        
        let logs = try await self.eth_getLogs(addresses: addresses, topics: topics, fromBlock: fromBlock, toBlock: toBlock)
        return try await handleLogs(logs, matches)
    }
        
    private func handleLogs(_ logs: [EthereumLog]?,
                            _ matches: [EventFilter]) async throws -> ([ABIEvent], [EthereumLog]) {
        
        guard let logs1 = logs else { return ([], []) }
        
        var events: [ABIEvent] = []
        var unprocessed: [EthereumLog] = []
        
        var filtersBySignature: [String: [EventFilter]] = [:]
        for filter in matches {
            if let sig = try? filter.type.signature() {
                var filters = filtersBySignature[sig, default: [EventFilter]()]
                filters.append(filter)
                filtersBySignature[sig] = filters
            }
        }
        
        let parseEvent: (EthereumLog, ABIEvent.Type) throws -> ABIEvent = { log, eventType in
            let topicTypes = eventType.types.enumerated()
                .filter { eventType.typesIndexed[$0.offset] == true }
                .compactMap { $0.element }
            
            let dataTypes = eventType.types.enumerated()
                .filter { eventType.typesIndexed[$0.offset] == false }
                .compactMap { $0.element }
            
            let data = try ABIDecoder.decodeData(log.data, types: dataTypes, asArray: true)
            
            guard data.count == dataTypes.count else {
                throw EthereumClientError.unexpectedReturnValue
            }
            
            let rawTopics = Array(log.topics.dropFirst())
            
            let parsedTopics = try zip(rawTopics, topicTypes).map { pair in
                try ABIDecoder.decodeData(pair.0, types: [pair.1])
            }
            
            let eventOpt = try eventType.init(topics: parsedTopics.flatMap { $0 }, data: data, log: log) // as ABIEvent??)
            guard let event = eventOpt else {
                throw EthereumClientError.unexpectedReturnValue
            }
            
            return event
        }
        
        for log in logs1 {
            guard let signature = log.topics.first,
                  let filters = filtersBySignature[signature] else {
                      unprocessed.append(log)
                      continue
                  }
            
            for filter in filters {
                let allowedSenders = Set(filter.allowedSenders)
                if allowedSenders.count > 0 && !allowedSenders.contains(log.address) {
                    unprocessed.append(log)
                } else if let event = try? parseEvent(log, filter.type) {
                    events.append(event)
                } else {
                    unprocessed.append(log)
                }
            }
        }
        
        return (events, unprocessed)
    }
}
