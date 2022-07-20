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

    func send<T: Encodable, U: Decodable>(method: String, params: T, receive: U.Type, completionHandler: @escaping (Result<Any, Error>) -> Void) {
        if type(of: params) == [Any].self {
            // If params are passed in with Array<Any> and not caught, runtime fatal error
            completionHandler(.failure(JSONRPCError.encodingError))
            return
        }

        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        let id: Int = 1
        let rpcRequest = JSONRPCRequest(jsonrpc: "2.0", method: method, params: params, id: id)
        guard let encoded = try? JSONEncoder().encode(rpcRequest) else {
            completionHandler(.failure(JSONRPCError.encodingError))
            return
        }
        request.httpBody = encoded

        let task = session.dataTask(with: request) { data, response, _ in
            if let data = data {
                if let result = try? JSONDecoder().decode(JSONRPCResult<U>.self, from: data) {
                    completionHandler(.success(result.result))
                } else if let result = try? JSONDecoder().decode([JSONRPCResult<U>].self, from: data) {
                    let resultObjects = result.map { return $0.result }
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
