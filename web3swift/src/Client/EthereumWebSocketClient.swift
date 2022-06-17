//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
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

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public enum WebSocketState {
    case connecting
    case open
    case closed
}

public class EthereumWebSocketClient: BaseEthereumClient, EthereumClientWebSocketProtocol {
    public var delegate: EthereumWebSocketClientDelegate? {
        get {
            return provider.delegate
        }
        set {
            provider.delegate = newValue
        }
    }

    public var onReconnectCallback: (() -> Void)? {
        get {
            return provider.onReconnectCallback
        }
        set {
            provider.onReconnectCallback = newValue
        }
    }
    
    public var currentState: WebSocketState {
        return provider.currentState
    }

    private let networkQueue: OperationQueue

    private var provider: WebSocketNetworkProviderProtocol
    
    public init(url: URL,
                eventLoopGroupProvider: EventLoopGroupProvider = .createNew,
                configuration: WebSocketConfiguration = .init(),
                sessionConfig: URLSessionConfiguration = URLSession.shared.configuration,
                logger: Logger? = nil) {
        let networkQueue = OperationQueue()
        networkQueue.name = "web3swift.client.networkQueue"
        networkQueue.qualityOfService = .background
        networkQueue.maxConcurrentOperationCount = 4
        self.networkQueue = networkQueue

        let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: networkQueue)

        let provider = WebSocketNetworkProvider(url: url.absoluteString,
                                                eventLoopGroupProvider: eventLoopGroupProvider,
                                                configuration: configuration,
                                                session: session,
                                                logger: logger)
        self.provider = provider
        super.init(networkProvider: provider, url: url, logger: logger)
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

extension EthereumWebSocketClient {
    public func subscribe(type: EthereumSubscriptionType, completionHandler: @escaping (Result<EthereumSubscription, EthereumClientError>) -> Void) {
        networkProvider.send(method: "eth_subscribe", params: [type.method, type.params].compactMap { $0 }, receive: String.self, completionHandler: completionHandler) { result in
            switch result {
            case .success(let data):
                if let resDataString = data as? String {
                    let subscription = EthereumSubscription(type: type, id: resDataString)
                    self.provider.addSubscription(subscription, callback: { _ in })
                    completionHandler(.success(subscription))
                } else {
                    completionHandler(.failure(.unexpectedReturnValue))
                }
            case .failure(let error):
                self.failureHandler(error, completionHandler: completionHandler)
            }
        }
    }
    
    public func unsubscribe(_ subscription: EthereumSubscription, completionHandler: @escaping (Result<Bool, EthereumClientError>) -> Void) {
        networkProvider.send(method: "eth_unsubscribe", params: [subscription.id], receive: Bool.self, completionHandler: completionHandler) { result in
            switch result {
            case .success(let data):
                if let resDataBool = data as? Bool {
                    self.provider.removeSubscription(subscription)
                    completionHandler(.success(resDataBool))
                } else {
                    completionHandler(.failure(.unexpectedReturnValue))
                }
            case .failure(let error):
                self.failureHandler(error, completionHandler: completionHandler)
            }
        }
    }
    
    public func pendingTransactions(onSubscribe: @escaping (Result<EthereumSubscription, EthereumClientError>) -> Void, onData: @escaping (String) -> Void) {
        networkProvider.send(method: "eth_subscribe", params: [EthereumSubscriptionType.pendingTransactions.method], receive: String.self, completionHandler: onSubscribe) { result in
            switch result {
            case .success(let data):
                if let resDataString = data as? String {
                    let subscription = EthereumSubscription(type: .pendingTransactions, id: resDataString)
                    self.provider.addSubscription(subscription, callback: { object in
                        onData(object as! String)
                    })
                    onSubscribe(.success(subscription))
                } else {
                    onSubscribe(.failure(.unexpectedReturnValue))
                }
            case .failure(let error):
                self.failureHandler(error, completionHandler: onSubscribe)
            }
        }
    }
    
    public func newBlockHeaders(onSubscribe: @escaping (Result<EthereumSubscription, EthereumClientError>) -> Void, onData: @escaping (EthereumHeader) -> Void) {
        networkProvider.send(method: "eth_subscribe", params: [EthereumSubscriptionType.newBlockHeaders.method], receive: String.self, completionHandler: onSubscribe) { result in
            switch result {
            case .success(let data):
                if let resDataString = data as? String {
                    let subscription = EthereumSubscription(type: .newBlockHeaders, id: resDataString)
                    self.provider.addSubscription(subscription, callback: { object in
                        onData(object as! EthereumHeader)
                    })
                    onSubscribe(.success(subscription))
                } else {
                    onSubscribe(.failure(.unexpectedReturnValue))
                }
            case .failure(let error):
                self.failureHandler(error, completionHandler: onSubscribe)
            }
        }
    }
    
    public func syncing(onSubscribe: @escaping (Result<EthereumSubscription, EthereumClientError>) -> Void, onData: @escaping (EthereumSyncStatus) -> Void) {
        networkProvider.send(method: "eth_subscribe", params: [EthereumSubscriptionType.syncing.method], receive: String.self, completionHandler: onSubscribe) { result in
            switch result {
            case .success(let data):
                if let resDataString = data as? String {
                    let subscription = EthereumSubscription(type: .syncing, id: resDataString)
                    self.provider.addSubscription(subscription, callback: { object in
                        onData(object as! EthereumSyncStatus)
                    })
                    onSubscribe(.success(subscription))
                } else {
                    onSubscribe(.failure(.unexpectedReturnValue))
                }
            case .failure(let error):
                self.failureHandler(error, completionHandler: onSubscribe)
            }
        }
    }
}

// MARK: - Async/Await
extension EthereumWebSocketClient {
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
