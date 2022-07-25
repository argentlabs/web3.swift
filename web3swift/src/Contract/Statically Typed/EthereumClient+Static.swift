//
//  EthereumClient+Static.swift
//  web3swift
//
//  Created by Matt Marshall on 10/04/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation

public extension ABIFunction {
    func execute(withClient client: EthereumClientProtocol, account: EthereumAccountProtocol, completionHandler: @escaping(Result<String, EthereumClientError>) -> Void) {
        guard let tx = try? self.transaction() else {
            completionHandler(.failure(.encodeIssue))
            return
        }

        client.eth_sendRawTransaction(tx, withAccount: account, completionHandler: completionHandler)
    }

    func call<T: ABIResponse>(
        withClient client: EthereumClientProtocol,
        responseType: T.Type,
        block: EthereumBlock = .Latest,
        resolution: CallResolution = .noOffchain(failOnExecutionError: true),
        completionHandler: @escaping(Result<T, EthereumClientError>) -> Void
    ) {

        guard let tx = try? self.transaction() else {
            completionHandler(.failure(.encodeIssue))
            return
        }

        client.eth_call(tx,
                        resolution: resolution,
                        block: block) { result in

            let parseOrFail: (String) -> Void = { data in
                guard let response = (try? T(data: data)) else {
                    completionHandler(.failure(.decodeIssue))
                    return
                }

                completionHandler(.success(response))
                return
            }

            switch result {
            case .success(let data):
                parseOrFail(data)
            case .failure(let error):
                switch (error) {
                case (.executionError):
                    if resolution.failOnExecutionError {
                        completionHandler(.failure(error))
                        return
                    } else {
                        return parseOrFail("0x")
                    }
                default:
                    completionHandler(.failure(error))
                }
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

public struct EventFilter {
    public let type: ABIEvent.Type
    public let allowedSenders: [EthereumAddress]

    public init(type: ABIEvent.Type,
                allowedSenders: [EthereumAddress]) {
        self.type = type
        self.allowedSenders = allowedSenders
    }
}

public struct Events {
    let events: [ABIEvent]
    let logs: [EthereumLog]
}

public extension EthereumClientProtocol {
    typealias EventsCompletionHandler = (Result<Events, EthereumClientError>) -> Void

    func getEvents(addresses: [EthereumAddress]?,
                   orTopics: [[String]?]?,
                   fromBlock: EthereumBlock,
                   toBlock: EthereumBlock,
                   matching matches: [EventFilter],
                   completionHandler: @escaping EventsCompletionHandler) {
        self.eth_getLogs(addresses: addresses, orTopics: orTopics, fromBlock: fromBlock, toBlock: toBlock) { [weak self] result in
            self?.handleLogs(result, matches, completionHandler)
        }
    }

    func getEvents(addresses: [EthereumAddress]?,
                   orTopics: [[String]?]?,
                   fromBlock: EthereumBlock,
                   toBlock: EthereumBlock,
                   eventTypes: [ABIEvent.Type],
                   completionHandler: @escaping EventsCompletionHandler) {
        let unfiltered = eventTypes.map { EventFilter(type: $0, allowedSenders: []) }
        self.eth_getLogs(addresses: addresses, orTopics: orTopics, fromBlock: fromBlock, toBlock: toBlock) { [weak self] result in
            self?.handleLogs(result, unfiltered, completionHandler)
        }
    }

    func getEvents(addresses: [EthereumAddress]?,
                   topics: [String?]?,
                   fromBlock: EthereumBlock,
                   toBlock: EthereumBlock,
                   eventTypes: [ABIEvent.Type],
                   completionHandler: @escaping EventsCompletionHandler) {
        let unfiltered = eventTypes.map { EventFilter(type: $0, allowedSenders: []) }
        getEvents(addresses: addresses,
                  topics: topics,
                  fromBlock: fromBlock,
                  toBlock: toBlock,
                  matching: unfiltered,
                  completionHandler: completionHandler)
    }

    func getEvents(addresses: [EthereumAddress]?,
                   topics: [String?]?,
                   fromBlock: EthereumBlock,
                   toBlock: EthereumBlock,
                   matching matches: [EventFilter],
                   completionHandler: @escaping EventsCompletionHandler) {

        self.eth_getLogs(addresses: addresses, topics: topics, fromBlock: fromBlock, toBlock: toBlock) { [weak self] result in
            self?.handleLogs(result, matches, completionHandler)
        }
    }

    func handleLogs(_ result: Result<[EthereumLog], EthereumClientError>,
                    _ matches: [EventFilter],
                    _ completionHandler: EventsCompletionHandler) {
        switch result {
        case .failure(let error):
            completionHandler(.failure(error))
        case .success(let logs):
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
            completionHandler(.success(Events(events: events, logs: unprocessed)))
        }
    }
}

// MARK: - Async/Await
public extension ABIFunction {
    func execute(withClient client: EthereumClientProtocol, account: EthereumAccountProtocol) async throws -> String  {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            execute(withClient: client, account: account, completionHandler: continuation.resume)
        }
    }

    func call<T: ABIResponse>(withClient client: EthereumClientProtocol,
                              responseType: T.Type,
                              block: EthereumBlock = .Latest,
                              resolution: CallResolution = .noOffchain(failOnExecutionError: true)) async throws -> T {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<T, Error>) in
            call(withClient: client, responseType: responseType, block: block, resolution: resolution, completionHandler: continuation.resume)
        }
    }
}

public extension EthereumClientProtocol {
    func getEvents(addresses: [EthereumAddress]?,
                   orTopics: [[String]?]?,
                   fromBlock: EthereumBlock,
                   toBlock: EthereumBlock,
                   matching matches: [EventFilter]) async throws -> Events {

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Events, Error>) in
            self.getEvents(addresses: addresses, orTopics: orTopics, fromBlock: fromBlock, toBlock: toBlock, matching: matches, completionHandler: continuation.resume)
        }
    }

    func getEvents(addresses: [EthereumAddress]?,
                   orTopics: [[String]?]?,
                   fromBlock: EthereumBlock,
                   toBlock: EthereumBlock,
                   eventTypes: [ABIEvent.Type]) async throws -> Events {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Events, Error>) in
            self.getEvents(addresses: addresses, orTopics: orTopics, fromBlock: fromBlock, toBlock: toBlock, eventTypes: eventTypes, completionHandler: continuation.resume)
        }
    }

    func getEvents(addresses: [EthereumAddress]?,
                   topics: [String?]?,
                   fromBlock: EthereumBlock,
                   toBlock: EthereumBlock,
                   eventTypes: [ABIEvent.Type]) async throws -> Events {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Events, Error>) in
            self.getEvents(addresses: addresses, topics: topics, fromBlock: fromBlock, toBlock: toBlock, eventTypes: eventTypes, completionHandler: continuation.resume)
        }
    }

    func getEvents(addresses: [EthereumAddress]?,
                   topics: [String?]?,
                   fromBlock: EthereumBlock,
                   toBlock: EthereumBlock,
                   matching matches: [EventFilter]) async throws -> Events {

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Events, Error>) in
            self.getEvents(addresses: addresses, topics: topics, fromBlock: fromBlock, toBlock: toBlock, matching: matches, completionHandler: continuation.resume)
        }
    }
}

// MARK: - Deprecated
public extension ABIFunction {
    @available(*, deprecated, renamed: "execute(withClient:account:completionHandler:)")
    func execute(withClient client: EthereumClientProtocol, account: EthereumAccountProtocol, completion: @escaping((EthereumClientError?, String?) -> Void)) {
        execute(withClient: client, account: account) { result in
            switch result {
            case .success(let value):
                completion(nil, value)
            case.failure(let error):
                completion(error, nil)
            }
        }
    }

    @available(*, deprecated, renamed: "call(withClient:responseType:block:resolution:completionHandler:)")
    func call<T: ABIResponse>(withClient client: EthereumClientProtocol,
                              responseType: T.Type,
                              block: EthereumBlock = .Latest,
                              resolution: CallResolution = .noOffchain(failOnExecutionError: true),
                              completion: @escaping((EthereumClientError?, T?) -> Void)) {
        call(withClient: client, responseType: responseType) { result in
            switch result {
            case .success(let value):
                completion(nil, value)
            case.failure(let error):
                completion(error, nil)
            }
        }
    }
}

public extension EthereumClientProtocol {
    @available(*, deprecated, renamed: "EventsCompletionHandler")
    typealias EventsCompletion = (EthereumClientError?, [ABIEvent], [EthereumLog]) -> Void

    @available(*, deprecated, renamed: "getEvents(addresses:orTopics:fromBlock:toBlock:matching:completionHandler:)")
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

    @available(*, deprecated, renamed: "getEvents(addresses:orTopics:fromBlock:toBlock:eventTypes:completionHandler:)")
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

    @available(*, deprecated, renamed: "getEvents(addresses:topics:fromBlock:toBlock:eventTypes:completionHandler:)")
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

    @available(*, deprecated, renamed: "getEvents(addresses:topics:fromBlock:toBlock:matching:completionHandler:)")
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

    @available(*, deprecated)
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
