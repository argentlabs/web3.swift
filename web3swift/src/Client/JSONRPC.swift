//
//  JSONRPC.swift
//  web3swift
//
//  Created by Matt Marshall on 06/03/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

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

    public init(
        code: Int,
        message: String
    ) {
        self.code = code
        self.message = message
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

    public var isExecutionError: Bool {
        switch self {
        case .executionError:
            return true
        default:
            return false
        }
    }
}

public class EthereumRPC {

    // Swift4 warning bug - https://bugs.swift.org/browse/SR-6265
    // static func execute<T: Encodable, U: Decodable>(session: URLSession, url: URL, method: String, params: T, receive: U.Type, id: Int = 1, completion: @escaping ((Error?, JSONRPCResult<U>?) -> Void)) -> Void {
    public static func execute<T: Encodable, U: Decodable>(session: URLSession, url: URL, method: String, params: T, receive: U.Type, id: Int = 1, completion: @escaping ((Error?, Any?) -> Void)) -> Void {

        if type(of: params) == [Any].self {
            // If params are passed in with Array<Any> and not caught, runtime fatal error
            completion(JSONRPCError.encodingError, nil)
            return
        }

        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        let rpcRequest = JSONRPCRequest(jsonrpc: "2.0", method: method, params: params, id: id)
        guard let encoded = try? JSONEncoder().encode(rpcRequest) else {
            completion(JSONRPCError.encodingError, nil)
            return
        }
        request.httpBody = encoded

        let task = session.dataTask(with: request) { (data, response, error) in
            if let data = data {
                if let result = try? JSONDecoder().decode(JSONRPCResult<U>.self, from: data) {
                    return completion(nil, result.result)
                } else if let result = try? JSONDecoder().decode([JSONRPCResult<U>].self, from: data) {
                    let resultObjects = result.map{ return $0.result }
                    return completion(nil, resultObjects)
                } else if let errorResult = try? JSONDecoder().decode(JSONRPCErrorResult.self, from: data) {
                    print("Ethereum response error: \(errorResult.error)")
                    return completion(JSONRPCError.executionError(errorResult), nil)
                } else if let response = response as? HTTPURLResponse, response.statusCode < 200 || response.statusCode > 299 {
                    return completion(JSONRPCError.requestRejected(data), nil)
                } else {
                    return completion(JSONRPCError.noResult, nil)
                }
            }

            completion(JSONRPCError.unknownError, nil)
        }

        task.resume()
    }
}

#if compiler(>=5.5) && canImport(_Concurrency)

@available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
extension EthereumRPC {
    public static func execute<T: Encodable, U: Decodable>(session: URLSession, url: URL, method: String, params: T, receive: U.Type, id: Int = 1) async throws -> Any {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Any, Error>) in
            Self.execute(session: session, url: url, method: method, params: params, receive: receive, id: id) { error, result in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let result = result {
                    continuation.resume(returning: result)
                }
            }
        }
    }
}

#endif
