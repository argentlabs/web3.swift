//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation

public extension ABIFunction {
    func execute(withClient client: EthereumClientProtocol, account: EthereumAccountProtocol) async throws -> String {
        guard let tx = try? transaction() else {
            throw EthereumClientError.encodeIssue
        }

        return try await client.eth_sendRawTransaction(tx, withAccount: account)
    }

    func call<T: ABIResponse>(withClient client: EthereumClientProtocol,
                              responseType: T.Type,
                              block: EthereumBlock = .Latest,
                              resolution: CallResolution = .noOffchain(failOnExecutionError: true)) async throws -> T {

        guard let tx = try? transaction() else {
            throw EthereumClientError.encodeIssue
        }

        let parseOrFail: (String) throws -> T = { data in
            guard let response = (try? T(data: data)) else {
                throw EthereumClientError.decodeIssue
            }

            return response
        }

        do {
            let data = try await client.eth_call(tx, resolution: resolution, block: block)

            return try parseOrFail(data)
        } catch {
            if let error = error as? EthereumClientError {
                switch error {
                case .executionError:
                    if resolution.failOnExecutionError {
                        throw error
                    } else {
                        return try parseOrFail("0x")
                    }
                default:
                    throw error
                }
            }
            throw error
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
    public let events: [ABIEvent]
    public let logs: [EthereumLog]
}

public extension EthereumClientProtocol {
    func getEvents(addresses: [EthereumAddress]?,
                   orTopics: [[String]?]?,
                   fromBlock: EthereumBlock,
                   toBlock: EthereumBlock,
                   matching matches: [EventFilter]) async throws -> Events {

        let logs = try await eth_getLogs(addresses: addresses, orTopics: orTopics, fromBlock: fromBlock, toBlock: toBlock)
        return handleLogs(logs, matches)
    }

    func getEvents(addresses: [EthereumAddress]?,
                   orTopics: [[String]?]?,
                   fromBlock: EthereumBlock,
                   toBlock: EthereumBlock,
                   eventTypes: [ABIEvent.Type]) async throws -> Events {
        let unfiltered = eventTypes.map { EventFilter(type: $0, allowedSenders: []) }
        let logs = try await eth_getLogs(addresses: addresses, orTopics: orTopics, fromBlock: fromBlock, toBlock: toBlock)
        return handleLogs(logs, unfiltered)
    }

    func getEvents(addresses: [EthereumAddress]?,
                   topics: [String?]?,
                   fromBlock: EthereumBlock,
                   toBlock: EthereumBlock,
                   eventTypes: [ABIEvent.Type]) async throws -> Events {
        let unfiltered = eventTypes.map { EventFilter(type: $0, allowedSenders: []) }
        return try await getEvents(addresses: addresses, topics: topics, fromBlock: fromBlock, toBlock: toBlock, matching: unfiltered)
    }

    func getEvents(addresses: [EthereumAddress]?,
                   topics: [String?]?,
                   fromBlock: EthereumBlock,
                   toBlock: EthereumBlock,
                   matching matches: [EventFilter]) async throws -> Events {

        let logs = try await eth_getLogs(addresses: addresses, topics: topics, fromBlock: fromBlock, toBlock: toBlock)
        return handleLogs(logs, matches)
    }

    func handleLogs(_ logs: [EthereumLog],
                    _ matches: [EventFilter]) -> Events {
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
        return Events(events: events, logs: unprocessed)
    }
}

public extension EthereumClientProtocol {
    typealias EventsCompletionHandler = (Result<Events, Error>) -> Void

    func getEvents(addresses: [EthereumAddress]?,
                   orTopics: [[String]?]?,
                   fromBlock: EthereumBlock,
                   toBlock: EthereumBlock,
                   matching matches: [EventFilter],
                   completionHandler: @escaping EventsCompletionHandler) {
        Task {
            do {
                let result = try await getEvents(addresses: addresses, orTopics: orTopics, fromBlock: fromBlock, toBlock: toBlock, matching: matches)
                completionHandler(.success(result))
            } catch {
                completionHandler(.failure(error))
            }
        }
    }

    func getEvents(addresses: [EthereumAddress]?,
                   orTopics: [[String]?]?,
                   fromBlock: EthereumBlock,
                   toBlock: EthereumBlock,
                   eventTypes: [ABIEvent.Type],
                   completionHandler: @escaping EventsCompletionHandler) {
        Task {
            do {
                let result = try await getEvents(addresses: addresses, orTopics: orTopics, fromBlock: fromBlock, toBlock: toBlock, eventTypes: eventTypes)
                completionHandler(.success(result))
            } catch {
                completionHandler(.failure(error))
            }
        }
    }

    func getEvents(addresses: [EthereumAddress]?,
                   topics: [String?]?,
                   fromBlock: EthereumBlock,
                   toBlock: EthereumBlock,
                   eventTypes: [ABIEvent.Type],
                   completionHandler: @escaping EventsCompletionHandler) {
        Task {
            do {
                let result = try await getEvents(addresses: addresses, topics: topics, fromBlock: fromBlock, toBlock: toBlock, eventTypes: eventTypes)
                completionHandler(.success(result))
            } catch {
                completionHandler(.failure(error))
            }
        }
    }

    func getEvents(addresses: [EthereumAddress]?,
                   topics: [String?]?,
                   fromBlock: EthereumBlock,
                   toBlock: EthereumBlock,
                   matching matches: [EventFilter],
                   completionHandler: @escaping EventsCompletionHandler) {

        Task {
            do {
                let result = try await getEvents(addresses: addresses, topics: topics, fromBlock: fromBlock, toBlock: toBlock, matching: matches)
                completionHandler(.success(result))
            } catch {
                completionHandler(.failure(error))
            }
        }
    }
}
