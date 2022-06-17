//
//  JSONRPC.swift
//  web3swift
//
//  Created by Dionisios Karatzas on 16/6/22.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation

struct JSONRPCSubscriptionParams<T: Decodable>: Decodable {
    public var subscription: String
    public var result: T
}

struct JSONRPCSubscriptionResponse<T: Decodable>: Decodable {
    public var jsonrpc: String
    public var method: String
    public var params: JSONRPCSubscriptionParams<T>
}

struct JSONRPCRequest<T: Encodable>: Encodable {
    let jsonrpc: String
    let method: String
    let params: T
    let id: Int
}

public struct JSONRPCResult<T: Decodable>: Decodable {
    public var id: Int
    public var jsonrpc: String
    public var result: T
}

public struct JSONRPCErrorDetail: Decodable, Equatable, CustomStringConvertible {
    public var code: Int
    public var message: String
    public var data: String?

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

public struct JSONRPCErrorResult: Decodable {
    public var id: Int
    public var jsonrpc: String
    public var error: JSONRPCErrorDetail
}

public enum JSONRPCErrorCode {
    public static var invalidInput = -32000
    public static var tooManyResults = -32005
    public static var contractExecution = 3
}

public enum JSONRPCError: Error {
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
            return true
        default:
            return false
        }
    }
}
