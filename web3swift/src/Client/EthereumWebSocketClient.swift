//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

#if canImport(NIO)
    import NIO
    import BigInt
    import NIOSSL
    import Logging
    import NIOCore
    import Foundation
    import GenericJSON
    import NIOWebSocket

    #if canImport(FoundationNetworking)
        import FoundationNetworking
    #endif

    public enum WebSocketState {
        case connecting
        case open
        case closed
    }

    public class EthereumWebSocketClient: BaseEthereumClient {
        public var delegate: EthereumWebSocketClientDelegate? {
            get {
                provider.delegate
            }
            set {
                provider.delegate = newValue
            }
        }

        public var onReconnectCallback: (() -> Void)? {
            get {
                provider.onReconnectCallback
            }
            set {
                provider.onReconnectCallback = newValue
            }
        }

        public var currentState: WebSocketState {
            provider.currentState
        }

        private let networkQueue: OperationQueue

        private var provider: WebSocketNetworkProviderProtocol

        public init(
            url: URL,
            eventLoopGroupProvider: EventLoopGroupProvider = .createNew,
            configuration: WebSocketConfiguration = .init(),
            sessionConfig: URLSessionConfiguration = URLSession.shared.configuration,
            logger: Logger? = nil,
            network: EthereumNetwork? = nil
        ) {
            let networkQueue = OperationQueue()
            networkQueue.name = "web3swift.client.networkQueue"
            networkQueue.maxConcurrentOperationCount = 4
            self.networkQueue = networkQueue

            let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: networkQueue)

            let provider = WebSocketNetworkProvider(
                url: url.absoluteString,
                eventLoopGroupProvider: eventLoopGroupProvider,
                configuration: configuration,
                session: session,
                logger: logger
            )
            self.provider = provider
            super.init(networkProvider: provider, url: url, logger: logger, network: network)
        }

        public func connect() {
            provider.connect()
        }

        public func disconnect(code: WebSocketErrorCode = .goingAway) {
            provider.disconnect(code: code)
        }

        /// Additional public API method to refresh the connection if still open (close, re-open).
        /// For example, if the app suspects bad data / missed heart beats, it can try to refresh.
        public func refresh() {
            provider.refresh()
        }
    }

    extension EthereumWebSocketClient: EthereumClientWebSocketProtocol {
        public func subscribe(type: EthereumSubscriptionType) async throws -> EthereumSubscription {
            do {
                let data = try await networkProvider.send(method: "eth_subscribe", params: [type.method, type.params].compactMap { $0 }, receive: String.self)
                if let resDataString = data as? String {
                    let subscription = EthereumSubscription(type: type, id: resDataString)
                    provider.addSubscription(subscription, callback: { _ in })
                    return subscription
                } else {
                    throw EthereumClientError.unexpectedReturnValue
                }
            } catch {
                throw failureHandler(error)
            }
        }

        public func unsubscribe(_ subscription: EthereumSubscription) async throws -> Bool {
            do {
                let data = try await networkProvider.send(method: "eth_unsubscribe", params: [subscription.id], receive: Bool.self)
                if let resDataBool = data as? Bool {
                    provider.removeSubscription(subscription)
                    return resDataBool
                } else {
                    throw EthereumClientError.unexpectedReturnValue
                }
            } catch {
                throw failureHandler(error)
            }
        }

        public func pendingTransactions(onData: @escaping (String) -> Void) async throws -> EthereumSubscription {
            do {
                let data = try await networkProvider.send(method: "eth_subscribe", params: [EthereumSubscriptionType.pendingTransactions.method], receive: String.self)
                if let resDataString = data as? String {
                    let subscription = EthereumSubscription(type: .pendingTransactions, id: resDataString)
                    provider.addSubscription(subscription, callback: { object in
                        onData(object as! String)
                    })
                    return subscription
                } else {
                    throw EthereumClientError.unexpectedReturnValue
                }
            } catch {
                throw failureHandler(error)
            }
        }

        public func newBlockHeaders(onData: @escaping (EthereumHeader) -> Void) async throws -> EthereumSubscription {
            do {
                let data = try await networkProvider.send(method: "eth_subscribe", params: [EthereumSubscriptionType.newBlockHeaders.method], receive: String.self)
                if let resDataString = data as? String {
                    let subscription = EthereumSubscription(type: .newBlockHeaders, id: resDataString)
                    provider.addSubscription(subscription, callback: { object in
                        onData(object as! EthereumHeader)
                    })
                    return subscription
                } else {
                    throw EthereumClientError.unexpectedReturnValue
                }
            } catch {
                throw failureHandler(error)
            }
        }

        public func syncing(onData: @escaping (EthereumSyncStatus) -> Void) async throws -> EthereumSubscription {
            do {
                let data = try await networkProvider.send(method: "eth_subscribe", params: [EthereumSubscriptionType.syncing.method], receive: String.self)
                if let resDataString = data as? String {
                    let subscription = EthereumSubscription(type: .syncing, id: resDataString)
                    provider.addSubscription(subscription, callback: { object in
                        onData(object as! EthereumSyncStatus)
                    })
                    return subscription
                } else {
                    throw EthereumClientError.unexpectedReturnValue
                }
            } catch {
                throw failureHandler(error)
            }
        }
    }

    extension EthereumWebSocketClient {
        public func subscribe(type: EthereumSubscriptionType, completionHandler: @escaping (Result<EthereumSubscription, EthereumClientError>) -> Void) {
            Task {
                do {
                    let result = try await subscribe(type: type)
                    completionHandler(.success(result))
                } catch {
                    failureHandler(error, completionHandler: completionHandler)
                }
            }
        }

        public func unsubscribe(_ subscription: EthereumSubscription, completionHandler: @escaping (Result<Bool, EthereumClientError>) -> Void) {
            Task {
                do {
                    let result = try await unsubscribe(subscription)
                    completionHandler(.success(result))
                } catch {
                    failureHandler(error, completionHandler: completionHandler)
                }
            }
        }

        public func pendingTransactions(onSubscribe: @escaping (Result<EthereumSubscription, EthereumClientError>) -> Void, onData: @escaping (String) -> Void) {
            Task {
                do {
                    let result = try await pendingTransactions(onData: onData)
                    onSubscribe(.success(result))
                } catch {
                    failureHandler(error, completionHandler: onSubscribe)
                }
            }
        }

        public func newBlockHeaders(onSubscribe: @escaping (Result<EthereumSubscription, EthereumClientError>) -> Void, onData: @escaping (EthereumHeader) -> Void) {
            Task {
                do {
                    let result = try await newBlockHeaders(onData: onData)
                    onSubscribe(.success(result))
                } catch {
                    failureHandler(error, completionHandler: onSubscribe)
                }
            }
        }

        public func syncing(onSubscribe: @escaping (Result<EthereumSubscription, EthereumClientError>) -> Void, onData: @escaping (EthereumSyncStatus) -> Void) {
            Task {
                do {
                    let result = try await syncing(onData: onData)
                    onSubscribe(.success(result))
                } catch {
                    failureHandler(error, completionHandler: onSubscribe)
                }
            }
        }
    }

#endif
