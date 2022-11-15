//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public enum OffchainReadError: Error {
    case network
    case server(code: Int, message: String?)
    case invalidParams
    case invalidResponse
    case tooManyRedirections
}

extension BaseEthereumClient {
    public func eth_call(_ transaction: EthereumTransaction,
                         block: EthereumBlock = .Latest) async throws -> String {
        return try await eth_call(transaction, resolution: .noOffchain(failOnExecutionError: true), block: block)
    }

    public func eth_call(_ transaction: EthereumTransaction,
                         resolution: CallResolution = .noOffchain(failOnExecutionError: true),
                         block: EthereumBlock = .Latest) async throws -> String {
        guard let transactionData = transaction.data else {
            throw EthereumClientError.noInputData
        }

        struct CallParams: Encodable {
            let from: String?
            let to: String
            let data: String
            let block: String

            enum TransactionCodingKeys: String, CodingKey {
                case from
                case to
                case data
            }

            func encode(to encoder: Encoder) throws {
                var container = encoder.unkeyedContainer()
                var nested = container.nestedContainer(keyedBy: TransactionCodingKeys.self)
                if let from = from {
                    try nested.encode(from, forKey: .from)
                }
                try nested.encode(to, forKey: .to)
                try nested.encode(data, forKey: .data)
                try container.encode(block)
            }
        }

        let params = CallParams(from: transaction.from?.value,
                                to: transaction.to.value,
                                data: transactionData.web3.hexString,
                                block: block.stringValue)
        do {
            let data = try await networkProvider.send(method: "eth_call", params: params, receive: String.self)

            if let resDataString = data as? String {
                return resDataString
            } else {
                throw EthereumClientError.unexpectedReturnValue
            }
        } catch {
            if case let .executionError(result) = error as? JSONRPCError {
                switch resolution {
                case .noOffchain:
                    throw EthereumClientError.executionError(result.error)
                case .offchainAllowed(let redirects):
                    if let lookup = result.offchainLookup, lookup.address == transaction.to {
                        do {
                            let data = try await self.offchainRead(lookup: lookup, maxReads: redirects)
                            return try await self.eth_call(.init(to: lookup.address,
                                                                 data: lookup.encodeCall(withResponse: data)),
                                                           resolution: .noOffchain(failOnExecutionError: true),
                                                           block: block)
                        } catch {
                            throw EthereumClientError.noResultFound
                        }
                    } else {
                        throw EthereumClientError.executionError(result.error)
                    }
                }
            } else {
                throw EthereumClientError.unexpectedReturnValue
            }
        }
    }

    // OffchainReadError
    private func offchainRead(lookup: OffchainLookup,
                              attempt: Int = 1,
                              maxReads: Int = 4) async throws -> Data {
        guard !lookup.urls.isEmpty else {
            throw OffchainReadError.invalidResponse
        }

        let url = lookup.urls[0]

        do {
            return try await offchainRead(sender: lookup.address,
                                          data: lookup.callData,
                                          rawURL: url,
                                          attempt: attempt,
                                          maxAttempts: maxReads)
        } catch {
            guard let error = error as? OffchainReadError, error.isNextURLAllowed else {
                throw error
            }

            var lookup = lookup
            lookup.urls = Array(lookup.urls.dropFirst())
            return try await offchainRead(lookup: lookup,
                                               attempt: attempt + 1,
                                               maxReads: maxReads)
        }
    }

    private func offchainRead(sender: EthereumAddress,
                              data: Data,
                              rawURL: String,
                              attempt: Int,
                              maxAttempts: Int) async throws -> Data {
        guard attempt <= maxAttempts else {
            throw OffchainReadError.tooManyRedirections
        }

        let isGet = rawURL.contains("{data}")

        guard let url = URL(string: rawURL
            .replacingOccurrences(of: "{sender}", with: sender.value.lowercased())
            .replacingOccurrences(of: "{data}", with: data.web3.hexString.lowercased()))
        else {
            throw OffchainReadError.invalidParams
        }

        var request = URLRequest(url: url)
        request.httpMethod = isGet ? "GET" : "POST"
        if !isGet {
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONEncoder().encode(
                OffchainReadJSONBody(
                    sender: sender,
                    data: data.web3.hexString
                )
            )
        }
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await networkProvider.session.data(for: request)

            guard let res = response as? HTTPURLResponse else {
                throw OffchainReadError.network
            }

            guard res.statusCode >= 200, res.statusCode < 300 else {
                let error = try? JSONDecoder().decode(OffchainReadErrorResponse.self, from: data)
                throw OffchainReadError.server(
                    code: res.statusCode,
                    message: error?.message ?? nil
                )
            }

            guard let decoded = try? JSONDecoder().decode(OffchainReadResponse.self, from: data) else {
                throw OffchainReadError.invalidResponse
            }

            return decoded.data
        } catch {
            throw error as? OffchainReadError ?? OffchainReadError.network
        }
    }
}

private struct OffchainReadJSONBody: Encodable {
    let sender: EthereumAddress
    let data: String
}

private struct OffchainReadResponse: Decodable {
    @DataStr
    var data: Data
}

private struct OffchainReadErrorResponse: Decodable {
    let message: String?
    let pathname: String
}

fileprivate extension OffchainReadError {
    var isNextURLAllowed: Bool {
        switch self {
        case let .server(code, _):
            return code >= 500 // 4xx responses -> Don't continue with next url
        case .network, .invalidParams, .invalidResponse:
            return true
        case .tooManyRedirections:
            return false
        }
    }
}

extension BaseEthereumClient {
    public func eth_call(_ transaction: EthereumTransaction,
                         block: EthereumBlock = .Latest,
                         completionHandler: @escaping (Result<String, EthereumClientError>) -> Void) {
        eth_call(transaction, resolution: .noOffchain(failOnExecutionError: true), block: block, completionHandler: completionHandler)
    }

    public func eth_call(_ transaction: EthereumTransaction,
                         resolution: CallResolution = .noOffchain(failOnExecutionError: true),
                         block: EthereumBlock = .Latest,
                         completionHandler: @escaping (Result<String, EthereumClientError>) -> Void) {
        Task {
            do {
                let result = try await eth_call(transaction, resolution: resolution, block: block)
                completionHandler(.success(result))
            } catch {
                completionHandler(.failure(error as! EthereumClientError))
            }
        }
    }
}
