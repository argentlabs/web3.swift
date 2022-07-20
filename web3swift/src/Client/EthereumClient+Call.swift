//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation
#if canImport(Combine)
import Combine
#else
import OpenCombine
import OpenCombineFoundation
#endif
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
                         block: EthereumBlock = .Latest,
                         completionHandler: @escaping (Result<String, EthereumClientError>) -> Void) {
        eth_call(transaction, resolution: .noOffchain(failOnExecutionError: true), block: block, completionHandler: completionHandler)
    }

    public func eth_call(
        _ transaction: EthereumTransaction,
        resolution: CallResolution = .noOffchain(failOnExecutionError: true),
        block: EthereumBlock = .Latest,
        completionHandler: @escaping (Result<String, EthereumClientError>) -> Void
    ) {
        guard let transactionData = transaction.data else {
            completionHandler(.failure(.noInputData))
            return
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

        let params = CallParams(
            from: transaction.from?.value,
            to: transaction.to.value,
            data: transactionData.web3.hexString,
            block: block.stringValue
        )

        networkProvider.send(method: "eth_call",
                             params: params,
                             receive: String.self) { result in
            switch result {
            case .success(let data):
                if let resDataString = data as? String {
                    completionHandler(.success(resDataString))
                } else {
                    completionHandler(.failure(.unexpectedReturnValue))
                }
            case .failure(let error):
                if case let .executionError(result) = error as? JSONRPCError {
                    switch resolution {
                    case .noOffchain:
                        completionHandler(.failure(.executionError(result.error)))
                    case .offchainAllowed(let redirects):
                        if let lookup = result.offchainLookup, lookup.address == transaction.to {
                            self.offchainRead(
                                lookup: lookup,
                                maxReads: redirects
                            ).sink(receiveCompletion: { offchainCompletion in
                                if case .failure = offchainCompletion {
                                    completionHandler(.failure(.noResultFound))
                                }
                            }, receiveValue: { data in
                                self.eth_call(
                                    .init(
                                        to: lookup.address,
                                        data: lookup.encodeCall(withResponse: data)
                                    ),
                                    resolution: .noOffchain(failOnExecutionError: true),
                                    block: block, completionHandler: completionHandler
                                )
                            }
                            )
                            .store(in: &cancellables)
                        } else {
                            completionHandler(.failure(.executionError(result.error)))
                        }
                    }
                } else {
                    completionHandler(.failure(.unexpectedReturnValue))
                }
            }
        }
    }

    private func offchainRead(
        lookup: OffchainLookup,
        attempt: Int = 1,
        maxReads: Int = 4
    ) -> AnyPublisher<Data, OffchainReadError> {
        guard !lookup.urls.isEmpty else {
            return Fail(error: OffchainReadError.invalidResponse)
                .eraseToAnyPublisher()
        }

        let url = lookup.urls[0]

        return offchainRead(
            sender: lookup.address,
            data: lookup.callData,
            rawURL: url,
            attempt: attempt,
            maxAttempts: maxReads
        )
        .catch { error -> AnyPublisher<Data, OffchainReadError> in
            guard error.isNextURLAllowed else {
                return Fail(error: error)
                    .eraseToAnyPublisher()
            }
            var lookup = lookup
            lookup.urls = Array(lookup.urls.dropFirst())
            return self.offchainRead(
                lookup: lookup,
                attempt: attempt + 1,
                maxReads: maxReads
            ).eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }

    private func offchainRead(
        sender: EthereumAddress,
        data: Data,
        rawURL: String,
        attempt: Int,
        maxAttempts: Int
    ) -> AnyPublisher<Data, OffchainReadError> {
        guard attempt <= maxAttempts else {
            return Fail(error: OffchainReadError.tooManyRedirections)
                .eraseToAnyPublisher()
        }

        let isGet = rawURL.contains("{data}")

        guard
            let url = URL(
                string: rawURL
                    .replacingOccurrences(of: "{sender}", with: sender.value.lowercased())
                    .replacingOccurrences(of: "{data}", with: data.web3.hexString.lowercased())
            )
        else {
            return Fail(error: OffchainReadError.invalidParams)
                .eraseToAnyPublisher()
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

        return networkProvider.session.dataTaskPublisher(for: request)
            .tryMap { data, response in
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
            }
            .mapError { error in
                error as? OffchainReadError ?? OffchainReadError.network
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Async/Await
extension BaseEthereumClient {
    public func eth_call(_ transaction: EthereumTransaction,
                         block: EthereumBlock = .Latest) async throws -> String {
        return try await eth_call(transaction, resolution: .noOffchain(failOnExecutionError: true), block: block)
    }

    public func eth_call(_ transaction: EthereumTransaction,
                         resolution: CallResolution = .noOffchain(failOnExecutionError: true),
                         block: EthereumBlock = .Latest) async throws -> String {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            eth_call(
                transaction,
                resolution: resolution,
                block: block,
                completionHandler: continuation.resume)
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

private var cancellables = Set<AnyCancellable>()

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
