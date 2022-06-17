//
//  NetworkProviderProtocol.swift
//  web3swift
//
//  Created by Dionisios Karatzas on 16/6/22.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation
import NIOWebSocket

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

internal protocol NetworkProviderProtocol {
    var session: URLSession { get }
    func send<T, P: Encodable, U: Decodable>(method: String, params: P, receive: U.Type, completionHandler: @escaping (Result<T, EthereumClientError>) -> Void, resultDecodeHandler: @escaping (Result<Any, Error>) -> Void)
}

internal protocol WebSocketNetworkProviderProtocol: NetworkProviderProtocol {
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
