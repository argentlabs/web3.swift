//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

#if canImport(NIO)

import Foundation
import NIOSSL

public struct WebSocketConfiguration {
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

    public init(tlsConfiguration: TLSConfiguration? = nil,
                maxFrameSize: Int = 1 << 14,
                automaticOpen: Bool = true,
                reconnectInterval: Int = 1000,
                maxReconnectInterval: Int = 30000,
                reconnectDecay: Double = 1.5,
                maxReconnectAttempts: Int = 0) {
        self.tlsConfiguration = tlsConfiguration
        self.maxFrameSize = maxFrameSize
        self.automaticOpen = automaticOpen
        self.reconnectInterval = reconnectInterval
        self.maxReconnectInterval = maxReconnectInterval
        self.reconnectDecay = reconnectDecay
        self.maxReconnectAttempts = maxReconnectAttempts
    }
}

#endif
