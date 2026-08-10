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
    public static let contractExecution = 3
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
