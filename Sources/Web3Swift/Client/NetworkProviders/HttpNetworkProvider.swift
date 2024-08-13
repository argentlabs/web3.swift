//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

public class HttpNetworkProvider: NetworkProviderProtocol {
    public let session: URLSession
    private let url: URL
    private let headers: [String: String]

    public init(session: URLSession, url: URL, headers: [String: String]? = nil) {
        self.session = session
        self.url = url
        self.headers = headers ?? [:]
    }

    deinit {
        session.invalidateAndCancel()
    }

    public func send<P, U>(method: String, params: P, receive: U.Type) async throws -> Any where P: Encodable, U: Decodable {
        if type(of: params) == [Any].self {
            // If params are passed in with Array<Any> and not caught, runtime fatal error
            throw JSONRPCError.encodingError
        }

        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        headers.forEach { key, value in
            request.addValue(value, forHTTPHeaderField: key)
        }

        let id = 1
        let rpcRequest = JSONRPCRequest(jsonrpc: "2.0", method: method, params: params, id: id)
        guard let encoded = try? JSONEncoder().encode(rpcRequest) else {
            throw JSONRPCError.encodingError
        }
        request.httpBody = encoded

        guard let (data, response) = try? await session.data(for: request) else {
            throw JSONRPCError.unknownError
        }
        if let result = try? JSONDecoder().decode(JSONRPCResult<U>.self, from: data) {
            return result.result
        } else if let result = try? JSONDecoder().decode([JSONRPCResult<U>].self, from: data) {
            let resultObjects = result.map { $0.result }
            return resultObjects
        } else if let errorResult = try? JSONDecoder().decode(JSONRPCErrorResult.self, from: data) {
            throw JSONRPCError.executionError(errorResult)
        } else if let response = response as? HTTPURLResponse, response.statusCode < 200 || response.statusCode > 299 {
            throw JSONRPCError.requestRejected(data)
        } else {
            throw JSONRPCError.noResult
        }
    }
}
