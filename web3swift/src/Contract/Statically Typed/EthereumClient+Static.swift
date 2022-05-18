//
//  EthereumClient+Static.swift
//  web3swift
//
//  Created by Matt Marshall on 10/04/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation

public extension ABIFunction {
    func execute(withClient client: EthereumClientProtocol, account: EthereumAccountProtocol, completion: @escaping((EthereumClientError?, String?) -> Void)) {

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

    func call<T: ABIResponse>(
        withClient client: EthereumClientProtocol,
        responseType: T.Type,
        block: EthereumBlock = .Latest,
        resolution: CallResolution = .noOffchain(failOnExecutionError: true),
        completion: @escaping((EthereumClientError?, T?) -> Void)
    ) {

        guard let tx = try? self.transaction() else {
            return completion(EthereumClientError.encodeIssue, nil)
        }

        client.eth_call(
            tx,
            resolution: resolution,
            block: block
        ) { (error, res) in
            let parseOrFail: (String) -> Void = { data in
                guard let response = (try? T(data: data)) else {
                    return completion(EthereumClientError.decodeIssue, nil)
                }

                return completion(nil, response)
            }

            switch (error, res) {
            case (.executionError, _):
                if resolution.failOnExecutionError {
                    return completion(error, nil)
                } else {
                    return parseOrFail("0x")
                }
            case (let error?, _):
                return completion(error, nil)
            case (nil, let data?):
                parseOrFail(data)
            case (nil, nil):
                return completion(EthereumClientError.unexpectedReturnValue, nil)
            }
        }
    }
}

extension CallResolution {
    var failOnExecutionError: Bool {
        switch self {
        case .noOffchain(let fail):
            return fail
        case .offchainAllowed:
            return true
        }
    }

    var allowsOffchain: Bool {
        switch self {
        case .noOffchain:
            return false
        case .offchainAllowed:
            return true
        }
    }
}

#if compiler(>=5.5) && canImport(_Concurrency)

@available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
public extension ABIFunction {
    func execute(withClient client: EthereumClientProtocol, account: EthereumAccountProtocol) async throws -> String  {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            execute(withClient: client, account: account) { error, response in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let response = response {
                    continuation.resume(returning: response)
                }
            }
        }
    }

    func call<T: ABIResponse>(
        withClient client: EthereumClientProtocol,
        responseType: T.Type,
        block: EthereumBlock = .Latest,
        resolution: CallResolution = .noOffchain(failOnExecutionError: true)
    ) async throws -> T {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<T, Error>) in
            call(
                withClient: client,
                responseType: responseType,
                block: block,
                resolution: resolution
            ) { error, response in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let response = response {
                    continuation.resume(returning: response)
                }
            }
        }
    }
}
#endif

public struct EventFilter {
    public let type: ABIEvent.Type
    public let allowedSenders: [EthereumAddress]

    public init(type: ABIEvent.Type,
                allowedSenders: [EthereumAddress]) {
        self.type = type
        self.allowedSenders = allowedSenders
    }
}

public extension EthereumClientProtocol {
    typealias EventsCompletion = (EthereumClientError?, [ABIEvent], [EthereumLog]) -> Void
    func getEvents(addresses: [EthereumAddress]?,
                   orTopics: [[String]?]?,
                   fromBlock: EthereumBlock,
                   toBlock: EthereumBlock,
                   matching matches: [EventFilter],
                   completion: @escaping EventsCompletion) {
        self.eth_getLogs(addresses: addresses, orTopics: orTopics, fromBlock: fromBlock, toBlock: toBlock) { [weak self] (error, logs) in
            self?.handleLogs(error, logs, matches, completion)
        }
    }

    func getEvents(addresses: [EthereumAddress]?,
                   orTopics: [[String]?]?,
                   fromBlock: EthereumBlock,
                   toBlock: EthereumBlock,
                   eventTypes: [ABIEvent.Type],
                   completion: @escaping EventsCompletion) {
        let unfiltered = eventTypes.map { EventFilter(type: $0, allowedSenders: []) }
        self.eth_getLogs(addresses: addresses, orTopics: orTopics, fromBlock: fromBlock, toBlock: toBlock) { [weak self] (error, logs) in
            self?.handleLogs(error, logs, unfiltered, completion)
        }
    }

    func getEvents(addresses: [EthereumAddress]?,
                   topics: [String?]?,
                   fromBlock: EthereumBlock,
                   toBlock: EthereumBlock,
                   eventTypes: [ABIEvent.Type],
                   completion: @escaping EventsCompletion) {
        let unfiltered = eventTypes.map { EventFilter(type: $0, allowedSenders: []) }
        getEvents(addresses: addresses,
                  topics: topics,
                  fromBlock: fromBlock,
                  toBlock: toBlock,
                  matching: unfiltered,
                  completion: completion)
    }

    func getEvents(addresses: [EthereumAddress]?,
                   topics: [String?]?,
                   fromBlock: EthereumBlock,
                   toBlock: EthereumBlock,
                   matching matches: [EventFilter],
                   completion: @escaping EventsCompletion) {

        self.eth_getLogs(addresses: addresses, topics: topics, fromBlock: fromBlock, toBlock: toBlock) { [weak self] (error, logs) in
            self?.handleLogs(error, logs, matches, completion)
        }
    }

    func handleLogs(_ error: EthereumClientError?,
                            _ logs: [EthereumLog]?,
                            _ matches: [EventFilter],
                            _ completion: EventsCompletion) {
        if let error = error {
            return completion(error, [], [])
        }

        guard let logs = logs else { return completion(nil, [], []) }

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

        let parseEvent: (EthereumLog, ABIEvent.Type) -> ABIEvent? = { log, eventType in
            let topicTypes = eventType.types.enumerated()
                .filter { eventType.typesIndexed[$0.offset] == true }
                .compactMap { $0.element }

            let dataTypes = eventType.types.enumerated()
                .filter { eventType.typesIndexed[$0.offset] == false }
                .compactMap { $0.element }

            guard let data = try? ABIDecoder.decodeData(log.data, types: dataTypes, asArray: true) else {
                return nil
            }

            guard data.count == dataTypes.count else {
                return nil
            }

            let rawTopics = Array(log.topics.dropFirst())

            guard let parsedTopics = (try? zip(rawTopics, topicTypes).map { pair in
                try ABIDecoder.decodeData(pair.0, types: [pair.1])
            }) else {
                return nil
            }

            guard let eventOpt = ((try? eventType.init(topics: parsedTopics.flatMap { $0 }, data: data, log: log)) as ABIEvent??), let event = eventOpt else {
                return nil
            }

            return event
        }

        for log in logs {
            guard let signature = log.topics.first,
                  let filters = filtersBySignature[signature] else {
                      unprocessed.append(log)
                      continue
                  }

            for filter in filters {
                let allowedSenders = Set(filter.allowedSenders)
                if allowedSenders.count > 0 && !allowedSenders.contains(log.address) {
                    unprocessed.append(log)
                } else if let event = parseEvent(log, filter.type) {
                    events.append(event)
                } else {
                    unprocessed.append(log)
                }
            }
        }

        return completion(error, events, unprocessed)
    }
}

#if compiler(>=5.5) && canImport(_Concurrency)

@available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
public struct Events {
    let events: [ABIEvent]
    let logs: [EthereumLog]
}

@available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
public extension EthereumClient {
    func getEvents(addresses: [EthereumAddress]?,
                   orTopics: [[String]?]?,
                   fromBlock: EthereumBlock,
                   toBlock: EthereumBlock,
                   matching matches: [EventFilter]) async throws -> Events {

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Events, Error>) in
            self.eth_getLogs(addresses: addresses, orTopics: orTopics, fromBlock: fromBlock, toBlock: toBlock) { [weak self] (error, logs) in
                self?.handleLogs(error, logs, matches) { error, events, logs in
                    if let error = error {
                        continuation.resume(throwing: error)
                    }
                    continuation.resume(returning: Events(events: events, logs: logs))
                }
            }
        }
    }

    func getEvents(addresses: [EthereumAddress]?,
                   orTopics: [[String]?]?,
                   fromBlock: EthereumBlock,
                   toBlock: EthereumBlock,
                   eventTypes: [ABIEvent.Type]) async throws -> Events {
        let unfiltered = eventTypes.map { EventFilter(type: $0, allowedSenders: []) }

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Events, Error>) in
            self.eth_getLogs(addresses: addresses, orTopics: orTopics, fromBlock: fromBlock, toBlock: toBlock) { [weak self] (error, logs) in
                self?.handleLogs(error, logs, unfiltered) { error, events, logs in
                    if let error = error {
                        continuation.resume(throwing: error)
                    }
                    continuation.resume(returning: Events(events: events, logs: logs))
                }
            }
        }
    }

    func getEvents(addresses: [EthereumAddress]?,
                   topics: [String?]?,
                   fromBlock: EthereumBlock,
                   toBlock: EthereumBlock,
                   eventTypes: [ABIEvent.Type]) async throws -> Events {
        let unfiltered = eventTypes.map { EventFilter(type: $0, allowedSenders: []) }
        return try await getEvents(addresses: addresses,
                                   topics: topics,
                                   fromBlock: fromBlock,
                                   toBlock: toBlock,
                                   matching: unfiltered)
    }

    func getEvents(addresses: [EthereumAddress]?,
                   topics: [String?]?,
                   fromBlock: EthereumBlock,
                   toBlock: EthereumBlock,
                   matching matches: [EventFilter]) async throws -> Events {

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Events, Error>) in
            self.eth_getLogs(addresses: addresses, topics: topics, fromBlock: fromBlock, toBlock: toBlock) { [weak self] (error, logs) in
                self?.handleLogs(error, logs, matches) { error, events, logs in
                    if let error = error {
                        continuation.resume(throwing: error)
                    }
                    continuation.resume(returning: Events(events: events, logs: logs))
                }
            }
        }
    }
}

#endif
