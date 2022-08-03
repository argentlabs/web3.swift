//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

class HttpNetworkProvider: NetworkProviderProtocol {
    let session: URLSession
    private let url: URL

    init(session: URLSession, url: URL) {
        self.session = session
        self.url = url
    }

    deinit {
        session.invalidateAndCancel()
    }

    func send<P, U>(method: String, params: P, receive: U.Type) async throws -> Any where P: Encodable, U: Decodable {
        if type(of: params) == [Any].self {
            // If params are passed in with Array<Any> and not caught, runtime fatal error
            throw JSONRPCError.encodingError
        }

        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        let id: Int = 1
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
            let resultObjects = result.map { return $0.result }
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
