//
//  web3.swift
//  Copyright © Argent Labs Limited. All rights reserved.
//

import Foundation
#if canImport(NIO)
    import NIOWebSocket
#endif

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

public protocol NetworkProviderProtocol: Sendable {
    var session: URLSession { get }
    func send<P: Encodable, U: Decodable>(method: String, params: P, receive: U.Type) async throws -> Any
}

#if canImport(NIO)
    protocol WebSocketNetworkProviderProtocol: NetworkProviderProtocol {
        var delegate: EthereumWebSocketClientDelegate? { get set }
        var onReconnectCallback: (() -> Void)? { get set }
        var currentState: WebSocketState { get }
        func connect()
        func disconnect(code: WebSocketErrorCode)
        func refresh()
        func reconnect()
        func addSubscription(_ subscription: EthereumSubscription, callback: @escaping (Any) -> Void)
        func removeSubscription(_ subscription: EthereumSubscription)
    }
#endif
