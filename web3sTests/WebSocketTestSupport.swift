//
//  web3.swift
//  Copyright © Argent Labs Limited. All rights reserved.
//

import Foundation
import XCTest

/// Environment variable that opts a run in to the WebSocket suites.
let webSocketTestsEnvironmentKey = "WEB3SWIFT_RUN_WEBSOCKET_TESTS"

extension XCTestCase {
    /// Skips a WebSocket suite unless explicitly enabled.
    ///
    /// Each `*WebSocketTests` class subclasses its HTTP counterpart and swaps in a WebSocket
    /// client, so it re-runs every test in the parent suite over WSS. That doubles the request
    /// volume against a shared, rate-limited node for almost no extra coverage — the duplicated
    /// tests exercise contract and decoding logic, not transport.
    ///
    /// Run them deliberately with:
    ///
    ///     WEB3SWIFT_RUN_WEBSOCKET_TESTS=1 swift test
    ///
    func skipUnlessWebSocketTestsEnabled() throws {
        guard ProcessInfo.processInfo.environment[webSocketTestsEnvironmentKey] == nil else {
            return
        }
        throw XCTSkip(
            "WebSocket suites duplicate their HTTP counterparts and double the load on a shared node. "
                + "Set \(webSocketTestsEnvironmentKey)=1 to run them."
        )
    }
}
