//
//  JSONRPC.swift
//  web3swift
//
//  Created by Matt Marshall on 06/03/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation

struct JSONRPCRequest<T: Encodable>: Encodable {
    let jsonrpc: String
    let method: String
    let params: T
    let id: Int
}

public struct JSONRPCResult<T: Decodable>: Decodable {
    var id: Int
    var jsonrpc: String
    var result: T
}

public struct JSONRPCErrorDetail: Decodable {
    var code: Int
    var message: String
}

public struct JSONRPCErrorResult: Decodable {
    var id: Int
    var jsonrpc: String
    var error: JSONRPCErrorDetail
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

    var isExecutionError: Bool {
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
    @available(*, deprecated, message: "Prefer async alternative instead")
    public static func execute<T: Encodable, U: Decodable>(session: URLSession, url: URL, method: String, params: T, receive: U.Type, id: Int = 1, completion: @escaping ((Error?, Any?) -> Void)) -> Void {
        async {
            do {
                let result: Any? = try await execute(session: session, url: url, method: method, params: params, receive: receive, id: id)
                completion(nil, result)
            } catch {
                completion(error, nil)
            }
        }
    }
    
    // TODO: Instead of Any, can't we return U?
    public static func execute<T: Encodable, U: Decodable>(session: URLSession, url: URL, method: String, params: T, receive: U.Type, id: Int = 1) async throws -> Any {
        
        if type(of: params) == [Any].self {
            // If params are passed in with Array<Any> and not caught, runtime fatal error
            throw JSONRPCError.encodingError
        }
        
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let rpcRequest = JSONRPCRequest(jsonrpc: "2.0", method: method, params: params, id: id)
        let encoded = try JSONEncoder().encode(rpcRequest)
        request.httpBody = encoded
        let (data, response) = try await session.data(for: request)
        
        if let result = try? JSONDecoder().decode(JSONRPCResult<U>.self, from: data) {
            return result.result
        } else if let result = try? JSONDecoder().decode([JSONRPCResult<U>].self, from: data) {
            let resultObjects = result.map{ return $0.result }
            return resultObjects
        } else if let errorResult = try? JSONDecoder().decode(JSONRPCErrorResult.self, from: data) {
            print("Ethereum response error: \(errorResult.error)")
            throw JSONRPCError.executionError(errorResult)
        } else if let response = response as? HTTPURLResponse, response.statusCode < 200 || response.statusCode > 299 {
            throw JSONRPCError.requestRejected(data)
        } else {
            throw JSONRPCError.noResult
        }
    }
}
