//
//  web3.swift
//  Copyright © Argent Labs Limited. All rights reserved.
//

import Foundation

struct JSONRPCSubscriptionParams<T: Sendable & Decodable>: Sendable, Decodable {
    var subscription: String
    var result: T
}

struct JSONRPCSubscriptionResponse<T: Sendable & Decodable>: Sendable, Decodable {
    var jsonrpc: String
    var method: String
    var params: JSONRPCSubscriptionParams<T>
}

struct JSONRPCRequest<T: Sendable & Encodable>: Sendable, Encodable {
    let jsonrpc: String
    let method: String
    let params: T
    let id: Int
}

public struct JSONRPCResult<T: Sendable & Decodable>: Sendable, Decodable {
    public var id: Int
    public var jsonrpc: String
    public var result: T
}

public struct JSONRPCErrorDetail: Sendable, Decodable, Equatable, CustomStringConvertible {
    public let code: Int
    public let message: String
    public let data: String?

    public init(
        code: Int,
        message: String,
        data: String?
    ) {
        self.code = code
        self.message = message
        self.data = data
    }

    public var description: String {
        "Code: \(code)\nMessage: \(message)"
    }
}

public struct JSONRPCErrorResult: Sendable, Decodable {
    public var id: Int
    public var jsonrpc: String
    public var error: JSONRPCErrorDetail
}

public enum JSONRPCErrorCode: Sendable {
    public static let invalidInput = -32000
    public static let tooManyResults = -32005
    public static let invalidParams = -32602
    public static let contractExecution = 3
}

extension JSONRPCErrorDetail {
    /// Whether this error means "your log query covers too much ground, narrow it".
    ///
    /// Nodes disagree on how to say it. Some use the dedicated `-32005`; others reject the
    /// request as generic invalid params (`-32602`) and only name the block-range limit in
    /// the message. Both are recoverable by splitting the range, so both map to
    /// `EthereumClientError.tooManyResults`.
    ///
    /// `-32602` on its own is *not* enough — it is also returned for genuinely malformed
    /// requests, which must surface rather than send the caller into a pointless recursion.
    var isLogRangeLimited: Bool {
        let text = message.lowercased()

        // Infura reuses -32005 for rate limiting ("Too Many Requests") as well as for oversized
        // log results. Splitting the range in that case would double the request count and make
        // the throttling worse, so treat it as a plain failure.
        guard !text.contains("too many requests") else {
            return false
        }

        if code == JSONRPCErrorCode.tooManyResults {
            return true
        }
        guard code == JSONRPCErrorCode.invalidParams else {
            return false
        }
        return text.contains("exceeds limit")
            || text.contains("block range")
            || text.contains("range is too large")
            || text.contains("query returned more than")
    }
}

public enum JSONRPCError: Sendable, Error {
    case executionError(JSONRPCErrorResult)
    case requestRejected(Data)
    case encodingError
    case decodingError
    case unknownError
    case noResult
    // WebSocket
    case invalidConnection
    case connectionNotOpen
    case connectionTimeout
    case pendingRequestsOnReconnecting
    case maxAttemptsReachedOnReconnecting

    public var isExecutionError: Bool {
        switch self {
        case .executionError:
            true
        default:
            false
        }
    }
}
