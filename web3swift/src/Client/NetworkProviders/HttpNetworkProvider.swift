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

    func send<T, P, U>(method: String, params: P, receive: U.Type, completionHandler: @escaping (Result<T, EthereumClientError>) -> Void, resultDecodeHandler: @escaping (Result<Any, Error>) -> Void) where P: Encodable, U: Decodable {
        if type(of: params) == [Any].self {
            // If params are passed in with Array<Any> and not caught, runtime fatal error
            resultDecodeHandler(.failure(JSONRPCError.encodingError))
            return
        }

        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        let id: Int = 1
        let rpcRequest = JSONRPCRequest(jsonrpc: "2.0", method: method, params: params, id: id)
        guard let encoded = try? JSONEncoder().encode(rpcRequest) else {
            resultDecodeHandler(.failure(JSONRPCError.encodingError))
            return
        }
        request.httpBody = encoded

        let task = session.dataTask(with: request) { data, response, _ in
            if let data = data {
                if let result = try? JSONDecoder().decode(JSONRPCResult<U>.self, from: data) {
                    resultDecodeHandler(.success(result.result))
                } else if let result = try? JSONDecoder().decode([JSONRPCResult<U>].self, from: data) {
                    let resultObjects = result.map { return $0.result }
                    resultDecodeHandler(.success(resultObjects))
                } else if let errorResult = try? JSONDecoder().decode(JSONRPCErrorResult.self, from: data) {
                    resultDecodeHandler(.failure(JSONRPCError.executionError(errorResult)))
                } else if let response = response as? HTTPURLResponse, response.statusCode < 200 || response.statusCode > 299 {
                    resultDecodeHandler(.failure(JSONRPCError.requestRejected(data)))
                } else {
                    resultDecodeHandler(.failure(JSONRPCError.noResult))
                }
            } else {
                resultDecodeHandler(.failure(JSONRPCError.unknownError))
            }
        }

        task.resume()
    }
}
