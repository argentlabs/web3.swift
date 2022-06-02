//
//  EthereumWebSocketClient.swift
//  web3swift
//
//  Created by Dionisis Karatzas on 1/6/22.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import BigInt
import Foundation
import NIO
import WebSocketKit
import Logging
import NIOSSL
import NIOCore
import NIOWebSocket
import GenericJSON

public class EthereumWebSocketClient: EthereumClientWebSocketProtocol {
    private struct JSONRPCSubscriptionParams<T: Decodable>: Decodable {
        public var subscription: String
        public var result: T
    }

    private struct JSONRPCSubscriptionResponse<T: Decodable>: Decodable {
        public var jsonrpc: String
        public var method: String
        public var params: JSONRPCSubscriptionParams<T>
    }

    private struct WebSocketRequest {
        var payload: String
        var callback: (Result<Data, EthereumClientError>) -> Void
    }

    private class SharedResources {
        private let semaphore = DispatchSemaphore(value: 1)
        // Requests that have not sent yet
        private(set) var requestQueue: [Int: WebSocketRequest] = [:]
        // Requests that have been sent and waiting for Response
        private(set) var responseQueue: [Int: WebSocketRequest] = [:]

        private(set) var subscriptions: [EthereumSubscription: (Any) -> Void] = [:]

        private(set) var counter: Int = 0 {
            didSet {
                if counter == Int.max {
                    counter = 0
                }
            }
        }

        func addRequest(_ key: Int, request: WebSocketRequest) {
            semaphore.wait()
            requestQueue[key] = request
            semaphore.signal()
        }

        func removeRequest(_ key: Int) {
            semaphore.wait()
            requestQueue.removeValue(forKey: key)
            semaphore.signal()
        }

        func addResponse(_ key: Int, request: WebSocketRequest) {
            semaphore.wait()
            responseQueue[key] = request
            semaphore.signal()
        }

        func removeResponse(_ key: Int) {
            semaphore.wait()
            responseQueue.removeValue(forKey: key)
            semaphore.signal()
        }

        func addSubscription(_ subscription: EthereumSubscription, callback: @escaping (Any) -> Void) {
            semaphore.wait()
            subscriptions[subscription] = callback
            semaphore.signal()
        }

        func removeSubscription(_ subscription: EthereumSubscription) {
            semaphore.wait()
            subscriptions.removeValue(forKey: subscription)
            semaphore.signal()
        }

        func incrementCounter() {
            semaphore.wait()
            counter += 1
            semaphore.signal()
        }

        func cleanSubscriptions() {
            semaphore.wait()
            subscriptions.removeAll()
            semaphore.signal()
        }
    }

    public enum EventLoopGroupProvider {
        case shared(EventLoopGroup)
        case createNew
    }

    public enum State {
        case connecting
        case open
        case closed
    }

    public struct Configuration {
        /// The TLS configuration for client use.
        public var tlsConfiguration: TLSConfiguration?
        /// The largest incoming `WebSocketFrame` size in bytes. Default is 16,384 bytes.
        public var maxFrameSize: Int
        /// Whether or not the websocket should attempt to connect immediately upon instantiation.
        public var automaticOpen: Bool
        /// The number of milliseconds to delay before attempting to reconnect.
        public var reconnectInterval: Int
        /// The maximum number of milliseconds to delay a reconnection attempt.
        public var maxReconnectInterval: Int
        /// The rate of increase of the reconnect delay. Allows reconnect attempts to back off when problems persist.
        public var reconnectDecay: Double
        /// The maximum number of reconnection attempts to make. Unlimited if zero.
        public var maxReconnectAttempts: Int

        public init(
            tlsConfiguration: TLSConfiguration? = nil,
            maxFrameSize: Int = 1 << 14,
            automaticOpen: Bool = true,
            reconnectInterval: Int = 1000,
            maxReconnectInterval: Int = 30000,
            reconnectDecay: Double = 1.5,
            maxReconnectAttempts: Int = 0

        ) {
            self.tlsConfiguration = tlsConfiguration
            self.maxFrameSize = maxFrameSize
            self.automaticOpen = automaticOpen
            self.reconnectInterval = reconnectInterval
            self.maxReconnectInterval = maxReconnectInterval
            self.reconnectDecay = reconnectDecay
            self.maxReconnectAttempts = maxReconnectAttempts
        }
    }

    public weak var delegate: EthereumWebSocketClientDelegate?
    public var onReconnectCallback: (() -> Void)?
    public let url: String
    public let eventLoopGroup: EventLoopGroup

    private(set) var currentState: State = .closed

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
                self.log.warning("Client has no network: \(error.localizedDescription)")
            }

            group.leave()
        }

        group.wait()
        return network
    }

    private let eventLoopGroupProvider: EventLoopGroupProvider
    private let log: Logger
    private let configuration: Configuration
    private let resources = SharedResources()

    private let semaphore = DispatchSemaphore(value: 1)
    private var reconnectAttempts = 0
    private var forcedClose = false
    private var timedOut = false

    private var retreivedNetwork: EthereumNetwork?
    private var webSocket: WebSocket?

    // won't ship with production code thanks to #if DEBUG
    // WebSocket is need it for testing purposes
#if DEBUG
    public func exposeWebSocket() -> WebSocket? {
        return self.webSocket
    }
#endif

    required public init(url: String,
                         eventLoopGroupProvider: EventLoopGroupProvider = .createNew,
                         configuration: Configuration = .init(),
                         logger: Logger? = nil) {
        self.url = url
        self.eventLoopGroupProvider = eventLoopGroupProvider
        switch eventLoopGroupProvider {
        case .shared(let group):
            self.eventLoopGroup = group
        case .createNew:
            self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        }
        self.log = logger ?? Logger(label: "web3.swift.eth-websocket-client")
        self.configuration = configuration

        // Whether or not to create a websocket upon instantiation
        if configuration.automaticOpen {
            connect(reconnectAttempt: false)
        }
    }

    deinit {
        self.log.trace("Shutting down WebSocket")
        disconnect()

        switch self.eventLoopGroupProvider {
        case .shared:
            self.log.trace("Running on shared EventLoopGroup. Not shutting down EventLoopGroup.")
        case .createNew:
            self.log.trace("Shutting down EventLoopGroup")
            do {
                try self.eventLoopGroup.syncShutdownGracefully()
            } catch {
                self.log.warning("Shutting down EventLoopGroup failed: \(error)")
            }
        }
    }

    public func connect() {
        connect(reconnectAttempt: false)
    }

    public func disconnect(code: WebSocketErrorCode = .goingAway) {
        do {
            forcedClose = true
            try webSocket?.close(code: code).wait()
        } catch {
            self.log.warning("Clossing WebSocket failed:  \(error)")
        }
    }

    /// Additional public API method to refresh the connection if still open (close, re-open).
    /// For example, if the app suspects bad data / missed heart beats, it can try to refresh.
    public func refresh() {
        do {
            try webSocket?.close(code: .goingAway).wait()
        } catch {
            self.log.warning("Failed to Close WebSocket: \(error)")
        }
    }

    private func connect(reconnectAttempt: Bool) {
        if let ws = webSocket, !ws.isClosed {
            return
        }

        if reconnectAttempt, configuration.maxReconnectAttempts > 0, self.reconnectAttempts > configuration.maxReconnectAttempts {
            self.log.trace("WebSocket reached maxReconnectAttempts. Stop trying")

            for request in resources.requestQueue {
                request.value.callback(.failure(.maxAttemptsReachedOnReconnecting))
                resources.removeRequest(request.key)
            }
            self.reconnectAttempts = 0
            return
        }

        self.log.trace("Requesting WebSocket connection")

        do {
            self.currentState = .connecting

            _ = try WebSocket.connect(to: url,
                                      configuration: WebSocketClient.Configuration(tlsConfiguration: configuration.tlsConfiguration,
                                                                                   maxFrameSize: configuration.maxFrameSize),
                                      on: eventLoopGroup) { ws in
                self.log.trace("WebSocket connected")

                if reconnectAttempt {
                    self.delegate?.onWebSocketReconnect()
                    self.onReconnectCallback?()
                }

                self.webSocket = ws
                self.currentState = .open
                self.reconnectAttempts = 0

                // Send pending requests and delete
                for request in self.resources.requestQueue {
                    ws.send(request.value.payload)
                    self.resources.removeRequest(request.key)
                }

                ws.onText { [weak self] _, string in
                    guard let self = self else { return }

                    if let data = string.data(using: .utf8),
                       let json = try? JSONDecoder().decode(JSON.self, from: data),
                       let subscriptionId = json["params"]?.objectValue?["subscription"]?.stringValue,
                       let subscription = self.resources.subscriptions.first(where: { $0.key.id == subscriptionId }) {
                        switch subscription.key.type {
                        case .newBlockHeaders:
                            if let data = string.data(using: .utf8), let response = try? JSONDecoder().decode(JSONRPCSubscriptionResponse<EthereumHeader>.self, from: data) {
                                self.delegate?.onNewBlockHeader(subscription: subscription.key, header: response.params.result)
                                subscription.value(response.params.result)
                            }
                        case .pendingTransactions:
                            if let data = string.data(using: .utf8), let response = try? JSONDecoder().decode(JSONRPCSubscriptionResponse<String>.self, from: data) {
                                self.delegate?.onNewPendingTransaction(subscription: subscription.key, txHash: response.params.result)
                                subscription.value(response.params.result)
                            }
                        case .syncing:
                            if let data = string.data(using: .utf8), let response = try? JSONDecoder().decode(JSONRPCSubscriptionResponse<EthereumSyncStatus>.self, from: data) {
                                self.delegate?.onSyncing(subscription: subscription.key, sync: response.params.result)
                                subscription.value(response.params.result)
                            }
                        }
                    }

                    if let data = string.data(using: .utf8),
                       let json = try? JSONDecoder().decode(JSON.self, from: data),
                       let responseId = json["id"]?.doubleValue {
                        guard let response = self.resources.responseQueue.first(where: { $0.key == Int(responseId) }) else { return }
                        response.value.callback(.success(data))
                        self.resources.removeResponse(response.key)
                    }
                }

                ws.onClose.whenComplete { value in
                    if let code = ws.closeCode {
                        self.log.trace("WebSocket closed. Code: \(code)")
                    } else {
                        self.log.trace("WebSocket closed")
                    }

                    for request in self.resources.requestQueue {
                        request.value.callback(.failure(.connectionNotOpen))
                        self.resources.removeRequest(request.key)
                    }

                    for response in self.resources.responseQueue {
                        response.value.callback(.failure(.invalidConnection))
                        self.resources.removeResponse(response.key)
                    }

                    self.resources.cleanSubscriptions()

                    if self.forcedClose {
                        self.currentState = .closed
                    } else {
                        self.currentState = .connecting

                        self.reconnect()
                    }
                }

            }.wait()
        } catch {
            currentState = .closed
            self.log.error("WebSocket connection failed: \(error)")

            for request in self.resources.requestQueue {
                request.value.callback(.failure(.connectionNotOpen))
                self.resources.removeRequest(request.key)
            }

            for response in self.resources.responseQueue {
                response.value.callback(.failure(.connectionNotOpen))
                self.resources.removeResponse(response.key)
            }

            self.resources.cleanSubscriptions()

            if case ChannelError.connectTimeout = error {
                reconnect()
            }
        }
    }

    private func encodeRequest<P: Encodable>(method: String, params: P, id: Int) throws -> String {
        let rpcRequest = JSONRPCRequest(jsonrpc: "2.0", method: method, params: params, id: id)
        log.trace("\(rpcRequest)")
        let data = try JSONEncoder().encode(rpcRequest)

        guard let dataString = String(data: data, encoding: .utf8) else {
            throw EthereumClientError.encodeIssue
        }

        return dataString
    }

    private func decoding<T: Decodable>(_ type: T.Type, then: @escaping (Result<Any, EthereumClientError>) -> Void) -> (Result<Data, EthereumClientError>) -> Void {
        return { dataResult in
            let decodedResult: Result<Any, EthereumClientError> = dataResult.tryMap { data in
                if let result = try? JSONDecoder().decode(JSONRPCResult<T>.self, from: data) {
                    return result.result
                } else if let result = try? JSONDecoder().decode([JSONRPCResult<T>].self, from: data) {
                    let resultObjects = result.map { return $0.result }
                    return resultObjects
                } else if let errorResult = try? JSONDecoder().decode(JSONRPCErrorResult.self, from: data) {
                    throw EthereumClientError.executionError(errorResult.error)
                } else {
                    throw EthereumClientError.unexpectedReturnValue
                }

            }
            then(decodedResult)
        }
    }

    private func send<T, P: Encodable, U: Decodable>(method: String, params: P, resultType: U.Type, completionHandler: @escaping (Result<T, EthereumClientError>) -> Void, resultDecodeHandler: @escaping (Result<Any, EthereumClientError>) -> Void) {
        semaphore.wait()

        defer {
            semaphore.signal()
        }
        resources.incrementCounter()
        let id = resources.counter

        let requestString: String

        do {
            requestString = try encodeRequest(method: method, params: params, id: id)
        } catch {
            completionHandler(.failure(.encodeIssue))
            return
        }

        let wsRequest = WebSocketRequest(payload: requestString, callback: decoding(resultType.self) { result in
            resultDecodeHandler(result)
        })

        // if socket is not connected yet or reconnecting
        // add request to the queue
        if currentState == .connecting {
            resources.addRequest(id, request: wsRequest)
            return
        }

        // if socket is closed remove pending request
        // and return failure
        if currentState != .open {
            resources.removeRequest(id)
            completionHandler(.failure(.connectionNotOpen))
            return
        }

        resources.addResponse(id, request: wsRequest)
        resources.removeRequest(id)

        let sendPromise = self.eventLoopGroup.next().makePromise(of: Void.self)
        sendPromise.futureResult.whenFailure({ error in
            completionHandler(.failure(.webSocketError(EquatableError(base: error))))
            self.resources.removeResponse(id)
        })
        webSocket?.send(requestString, promise: sendPromise)
    }

    private func reconnect() {
        for response in resources.responseQueue {
            response.value.callback(.failure(.pendingRequestsOnReconnecting))
            resources.removeResponse(response.key)
        }

        var delay = configuration.reconnectInterval * Int(pow(configuration.reconnectDecay, Double(reconnectAttempts)))
        if delay > configuration.maxReconnectInterval {
            delay = configuration.maxReconnectInterval
        }

        self.log.trace("WebSocket reconnecting... Delay: \(delay) ms")

        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(delay), execute: {
            self.reconnectAttempts += 1
            self.connect(reconnectAttempt: true)
        })
    }
}

extension EthereumWebSocketClient {
    public func net_version(completionHandler: @escaping (Result<EthereumNetwork, EthereumClientError>) -> Void) {
        send(method: "net_version", params: [Bool](), resultType: String.self, completionHandler: completionHandler) { result in
            let newResult: Result<EthereumNetwork, EthereumClientError> = result.tryMap { data in
                if let resString = data as? String {
                    let network = EthereumNetwork.fromString(resString)
                    return network
                } else {
                    throw EthereumClientError.unexpectedReturnValue
                }
            }
            completionHandler(newResult)
        }
    }

    public func eth_gasPrice(completionHandler: @escaping (Result<BigUInt, EthereumClientError>) -> Void) {
        send(method: "eth_gasPrice", params: [Bool](), resultType: String.self, completionHandler: completionHandler) { result in
            switch result {
            case .success(let data):
                if let hexString = data as? String, let bigUInt = BigUInt(hex: hexString) {
                    completionHandler(.success(bigUInt))
                } else {
                    completionHandler(.failure(.unexpectedReturnValue))
                }
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }

    public func eth_blockNumber(completionHandler: @escaping (Result<Int, EthereumClientError>) -> Void) {
        send(method: "eth_blockNumber", params: [Bool](), resultType: String.self, completionHandler: completionHandler) { result in
            let newResult: Result<Int, EthereumClientError> = result.tryMap { data in
                if let hexString = data as? String {
                    if let integerValue = Int(hex: hexString) {
                        return integerValue
                    } else {
                        throw EthereumClientError.decodeIssue
                    }
                } else {
                    throw EthereumClientError.unexpectedReturnValue
                }
            }
            completionHandler(newResult)
        }
    }

    public func eth_getBalance(address: EthereumAddress, block: EthereumBlock, completionHandler: @escaping (Result<BigUInt, EthereumClientError>) -> Void) {
        send(method: "eth_getBalance", params: [address.value, block.stringValue], resultType: String.self, completionHandler: completionHandler) { result in
            let newResult: Result<BigUInt, EthereumClientError> = result.tryMap { data in
                if let resString = data as? String, let balanceInt = BigUInt(hex: resString.web3.noHexPrefix) {
                    return balanceInt
                } else {
                    throw EthereumClientError.unexpectedReturnValue
                }
            }
            completionHandler(newResult)
        }
    }

    public func eth_getCode(address: EthereumAddress, block: EthereumBlock, completionHandler: @escaping (Result<String, EthereumClientError>) -> Void) {
        send(method: "eth_getCode", params: [address.value, block.stringValue], resultType: String.self, completionHandler: completionHandler) { result in
            let newResult: Result<String, EthereumClientError> = result.tryMap { data in
                if let resDataString = data as? String {
                    return resDataString
                } else {
                    throw EthereumClientError.unexpectedReturnValue
                }
            }
            completionHandler(newResult)
        }
    }

    public func eth_estimateGas(_ transaction: EthereumTransaction, completionHandler: @escaping (Result<BigUInt, EthereumClientError>) -> Void) {
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
                                gas: nil,
                                gasPrice: nil,
                                value: value?.web3.hexString,
                                data: transaction.data?.web3.hexString)

        send(method: "eth_estimateGas", params: params, resultType: String.self, completionHandler: completionHandler) { result in
            let newResult: Result<BigUInt, EthereumClientError> = result.tryMap { data in
                if let gasHex = data as? String, let gas = BigUInt(hex: gasHex) {
                    return gas
                } else {
                    throw EthereumClientError.unexpectedReturnValue
                }
            }
            completionHandler(newResult)
        }
    }

    public func eth_sendRawTransaction(_ transaction: EthereumTransaction, withAccount account: EthereumAccountProtocol, completionHandler: @escaping (Result<String, EthereumClientError>) -> Void) {
        Task {
            do {
                let nonce = try await self.eth_getTransactionCount(address: account.address, block: .Pending)

                var transaction = transaction
                transaction.nonce = nonce

                if transaction.chainId == nil, let network = self.network {
                    transaction.chainId = network.intValue
                }

                guard let _ = transaction.chainId, let signedTx = (try? account.sign(transaction: transaction)), let transactionHex = signedTx.raw?.web3.hexString else {
                    completionHandler(.failure(.encodeIssue))
                    return
                }

                send(method: "eth_sendRawTransaction", params: [transactionHex], resultType: String.self, completionHandler: completionHandler) { result in
                    let newResult: Result<String, EthereumClientError> = result.tryMap { data in
                        if let resDataString = data as? String {
                            return resDataString
                        } else {
                            throw EthereumClientError.unexpectedReturnValue
                        }
                    }
                    completionHandler(newResult)
                }
            } catch {
                completionHandler(.failure(error as! EthereumClientError))
            }
        }
    }

    public func eth_getTransactionCount(address: EthereumAddress, block: EthereumBlock, completionHandler: @escaping (Result<Int, EthereumClientError>) -> Void) {
        send(method: "eth_getTransactionCount", params: [address.value, block.stringValue], resultType: String.self, completionHandler: completionHandler) { result in
            let newResult: Result<Int, EthereumClientError> = result.tryMap { data in
                if let resString = data as? String, let count = Int(hex: resString) {
                    return count
                } else {
                    throw EthereumClientError.unexpectedReturnValue
                }
            }
            completionHandler(newResult)
        }
    }

    public func eth_getTransaction(byHash txHash: String, completionHandler: @escaping (Result<EthereumTransaction, EthereumClientError>) -> Void) {
        send(method: "eth_getTransactionByHash", params: [txHash], resultType: EthereumTransaction.self, completionHandler: completionHandler) { result in
            let newResult: Result<EthereumTransaction, EthereumClientError> = result.tryMap { data in
                if let transaction = data as? EthereumTransaction {
                    return transaction
                } else {
                    throw EthereumClientError.unexpectedReturnValue
                }
            }
            completionHandler(newResult)
        }
    }

    public func eth_getTransactionReceipt(txHash: String, completionHandler: @escaping (Result<EthereumTransactionReceipt, EthereumClientError>) -> Void) {
        send(method: "eth_getTransactionReceipt", params: [txHash], resultType: EthereumTransactionReceipt.self, completionHandler: completionHandler) { result in
            let newResult: Result<EthereumTransactionReceipt, EthereumClientError> = result.tryMap { data in
                if let receipt = data as? EthereumTransactionReceipt {
                    return receipt
                } else {
                    throw EthereumClientError.noResultFound
                }
            }
            completionHandler(newResult)
        }
    }


    public func eth_call(_ transaction: EthereumTransaction, block: EthereumBlock = .Latest, completionHandler: @escaping (Result<String, EthereumClientError>) -> Void) {
        guard let transactionData = transaction.data else {
            completionHandler(.failure(.noInputData))
            return
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

        let params = CallParams(
            from: transaction.from?.value,
            to: transaction.to.value,
            data: transactionData.web3.hexString,
            block: block.stringValue
        )
        send(method: "eth_call", params: params, resultType: String.self, completionHandler: completionHandler) { result in
            let newResult: Result<String, EthereumClientError> = result.tryMap { data in
                if let resDataString = data as? String {
                    return resDataString
                } else {
                    throw EthereumClientError.unexpectedReturnValue
                }
            }

            completionHandler(newResult)
        }
    }

    public func eth_call(_ transaction: EthereumTransaction, resolution: CallResolution = .noOffchain(failOnExecutionError: true), block: EthereumBlock = .Latest, completionHandler: @escaping (Result<String, EthereumClientError>) -> Void) {
        eth_call(transaction, completionHandler: completionHandler)
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

        send(method: "eth_getBlockByNumber", params: params, resultType: EthereumBlockInfo.self, completionHandler: completionHandler) { result in
            let newResult: Result<EthereumBlockInfo, EthereumClientError> = result.tryMap { data in
                if let blockData = data as? EthereumBlockInfo {
                    return blockData
                } else {
                    throw EthereumClientError.unexpectedReturnValue
                }
            }
            completionHandler(newResult)
        }
    }

    public func getLogs(addresses: [EthereumAddress]?, topics: Topics?, fromBlock: EthereumBlock, toBlock: EthereumBlock, completionHandler: @escaping ((Result<[EthereumLog], EthereumClientError>) -> Void)) {
        struct CallParams: Encodable {
            var fromBlock: String
            var toBlock: String
            let address: [EthereumAddress]?
            let topics: Topics?
        }

        let params = CallParams(fromBlock: fromBlock.stringValue, toBlock: toBlock.stringValue, address: addresses, topics: topics)
        send(method: "eth_getLogs", params: [params], resultType: [EthereumLog].self, completionHandler: completionHandler) { result in
            var newResult: Result<[EthereumLog], EthereumClientError> = result.tryMap { data in
                if let logs = data as? [EthereumLog] {
                    return logs
                } else {
                    throw EthereumClientError.unexpectedReturnValue
                }
            }

            newResult = newResult.mapError { error in
                if case let .executionError(innerError) = error,
                   innerError.code == JSONRPCErrorCode.tooManyResults {
                    return .tooManyResults
                } else {
                    return .unexpectedReturnValue
                }
            }

            completionHandler(newResult)
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

    public func subscribe(type: EthereumSubscriptionType, completionHandler: @escaping (Result<EthereumSubscription, EthereumClientError>) -> Void) {
        send(method: "eth_subscribe", params: [type.method, type.params].compactMap { $0 }, resultType: String.self, completionHandler: completionHandler) { result in
            let newResult: Result<EthereumSubscription, EthereumClientError> = result.tryMap { data in
                if let resDataString = data as? String {
                    let subscription = EthereumSubscription(type: type, id: resDataString)
                    self.resources.addSubscription(subscription, callback: { _ in })
                    return subscription
                } else {
                    throw EthereumClientError.unexpectedReturnValue
                }
            }
            completionHandler(newResult)
        }
    }

    public func unsubscribe(_ subscription: EthereumSubscription, completionHandler: @escaping (Result<Bool, EthereumClientError>) -> Void) {
        send(method: "eth_unsubscribe", params: [subscription.id], resultType: Bool.self, completionHandler: completionHandler) { result in
            let newResult: Result<Bool, EthereumClientError> = result.tryMap { data in
                if let resDataBool = data as? Bool {
                    self.resources.removeSubscription(subscription)
                    return resDataBool
                } else {
                    throw EthereumClientError.unexpectedReturnValue
                }
            }
            completionHandler(newResult)
        }
    }

    public func pendingTransactions(onSubscribe: @escaping (Result<EthereumSubscription, EthereumClientError>) -> Void, onData: @escaping (String) -> Void) {
        send(method: "eth_subscribe", params: [EthereumSubscriptionType.pendingTransactions.method], resultType: String.self, completionHandler: onSubscribe) { result in
            let newResult: Result<EthereumSubscription, EthereumClientError> = result.tryMap { data in
                if let resDataString = data as? String {
                    let subscription = EthereumSubscription(type: .pendingTransactions, id: resDataString)
                    self.resources.addSubscription(subscription, callback: { object in
                        onData(object as! String)
                    })
                    return subscription
                } else {
                    throw EthereumClientError.unexpectedReturnValue
                }
            }
            onSubscribe(newResult)
        }
    }

    public func newBlockHeaders(onSubscribe: @escaping (Result<EthereumSubscription, EthereumClientError>) -> Void, onData: @escaping (EthereumHeader) -> Void) {
        send(method: "eth_subscribe", params: [EthereumSubscriptionType.newBlockHeaders.method], resultType: String.self, completionHandler: onSubscribe) { result in
            let newResult: Result<EthereumSubscription, EthereumClientError> = result.tryMap { data in
                if let resDataString = data as? String {
                    let subscription = EthereumSubscription(type: .newBlockHeaders, id: resDataString)
                    self.resources.addSubscription(subscription, callback: { object in
                        onData(object as! EthereumHeader)
                    })
                    return subscription
                } else {
                    throw EthereumClientError.unexpectedReturnValue
                }
            }
            onSubscribe(newResult)
        }
    }

    public func syncing(onSubscribe: @escaping (Result<EthereumSubscription, EthereumClientError>) -> Void, onData: @escaping (EthereumSyncStatus) -> Void) {
        send(method: "eth_subscribe", params: [EthereumSubscriptionType.syncing.method], resultType: String.self, completionHandler: onSubscribe) { result in
            let newResult: Result<EthereumSubscription, EthereumClientError> = result.tryMap { data in
                if let resDataString = data as? String {
                    let subscription = EthereumSubscription(type: .syncing, id: resDataString)
                    self.resources.addSubscription(subscription, callback: { object in
                        onData(object as! EthereumSyncStatus)
                    })
                    return subscription
                } else {
                    throw EthereumClientError.unexpectedReturnValue
                }
            }
            onSubscribe(newResult)
        }
    }
}

// MARK: - Async/Await
extension EthereumWebSocketClient {
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

    public func eth_call(_ transaction: EthereumTransaction, block: EthereumBlock = .Latest) async throws -> String {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            eth_call(transaction, block: block, completionHandler: continuation.resume)
        }
    }

    public func eth_call(_ transaction: EthereumTransaction, resolution: CallResolution = .noOffchain(failOnExecutionError: true), block: EthereumBlock = .Latest) async throws -> String {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            eth_call(transaction, resolution: resolution, block: block, completionHandler: continuation.resume)
        }
    }

    public func subscribe(type: EthereumSubscriptionType) async throws -> EthereumSubscription {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<EthereumSubscription, Error>) in
            subscribe(type: type, completionHandler: continuation.resume)
        }
    }

    public func unsubscribe(_ subscription: EthereumSubscription) async throws -> Bool {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
            unsubscribe(subscription, completionHandler: continuation.resume)
        }
    }

    public func pendingTransactions(onData: @escaping (String) -> Void) async throws -> EthereumSubscription {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<EthereumSubscription, Error>) in
            pendingTransactions(onSubscribe: continuation.resume, onData: onData)
        }
    }

    public func newBlockHeaders(onData: @escaping (EthereumHeader) -> Void) async throws -> EthereumSubscription {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<EthereumSubscription, Error>) in
            newBlockHeaders(onSubscribe: continuation.resume, onData: onData)
        }
    }

    public func syncing(onData: @escaping (EthereumSyncStatus) -> Void) async throws -> EthereumSubscription {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<EthereumSubscription, Error>) in
            syncing(onSubscribe: continuation.resume, onData: onData)
        }
    }
}
