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
    public static func execute<T: Encodable, U: Decodable>(session: URLSession, url: URL, method: String, params: T, receive: U.Type, id: Int = 1, completionHandler:  @escaping(Result<Any, Error>) -> Void) {
        if type(of: params) == [Any].self {
            // If params are passed in with Array<Any> and not caught, runtime fatal error
            completionHandler(.failure(JSONRPCError.encodingError))
            return
        }

        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        let rpcRequest = JSONRPCRequest(jsonrpc: "2.0", method: method, params: params, id: id)
        guard let encoded = try? JSONEncoder().encode(rpcRequest) else {
            completionHandler(.failure(JSONRPCError.encodingError))
            return
        }
        request.httpBody = encoded

        let task = session.dataTask(with: request) { (data, response, error) in
            if let data = data {
                if let result = try? JSONDecoder().decode(JSONRPCResult<U>.self, from: data) {
                    completionHandler(.success(result.result))
                } else if let result = try? JSONDecoder().decode([JSONRPCResult<U>].self, from: data) {
                    let resultObjects = result.map{ return $0.result }
                    completionHandler(.success(resultObjects))
                } else if let errorResult = try? JSONDecoder().decode(JSONRPCErrorResult.self, from: data) {
                    completionHandler(.failure(JSONRPCError.executionError(errorResult)))
                } else if let response = response as? HTTPURLResponse, response.statusCode < 200 || response.statusCode > 299 {
                    completionHandler(.failure(JSONRPCError.requestRejected(data)))
                } else {
                    completionHandler(.failure(JSONRPCError.noResult))
                }
            } else {
                completionHandler(.failure(JSONRPCError.unknownError))
            }
        }

        task.resume()
    }
}

// MARK: - Async/Await
extension EthereumRPC {
    public static func execute<T: Encodable, U: Decodable>(session: URLSession, url: URL, method: String, params: T, receive: U.Type, id: Int = 1) async throws -> Any {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Any, Error>) in
            Self.execute(session: session, url: url, method: method, params: params, receive: receive, id: id, completionHandler: continuation.resume)
        }
    }
}

// MARK: - Deprecated
extension EthereumRPC {
    @available(*, deprecated, renamed: "execute(session:url:method:params:receive:id:completionHandler:)")
    public static func execute<T: Encodable, U: Decodable>(session: URLSession, url: URL, method: String, params: T, receive: U.Type, id: Int = 1, completion: @escaping ((Error?, Any?) -> Void)) -> Void {
        Self.execute(session: session, url: url, method: method, params: params, receive: receive, id: id) { result in
            switch result {
            case .success(let data):
                completion(nil, data)
            case .failure(let error):
                completion(error, nil)
            }
        }
    }
}
