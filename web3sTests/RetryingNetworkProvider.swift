//
//  web3.swift
//  Copyright © Argent Labs Limited. All rights reserved.
//

import Foundation
import web3

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

/// Retries requests that a provider rejected for sending them too quickly.
///
/// This lives in the test target deliberately.
///
/// Recognising "you are being throttled" means matching on provider prose, because there is no
/// standard signal for it. The same condition arrives as an HTTP 429 with `Too Many Requests`
/// from one provider, an HTTP 200 carrying JSON-RPC `-32005 rate limit exceeded` from another,
/// and an HTTP 200 carrying `-32603 service temporarily unavailable` from a third. Codes
/// collide too: Infura uses `-32005` for both throttling and oversized log results.
///
/// Guesswork like that is acceptable here — a wrong guess costs a re-run — but it does not
/// belong in library code, where a provider quietly rewording a message would change behaviour
/// for every consumer with no compile error and no failing test.
///
/// The real reason this is needed is that the suite makes hundreds of live RPC calls in under a
/// minute, which every free endpoint throttles. Recording responses and replaying them would
/// remove the need for this entirely.
final class RetryingNetworkProvider: NetworkProviderProtocol, @unchecked Sendable {
    private let wrapped: NetworkProviderProtocol
    private let maxRetries: Int

    var session: URLSession { wrapped.session }

    init(wrapping wrapped: NetworkProviderProtocol, maxRetries: Int = 4) {
        self.wrapped = wrapped
        self.maxRetries = maxRetries
    }

    func send<P: Encodable, U: Decodable>(method: String, params: P, receive: U.Type) async throws -> Any {
        var attempt = 0
        while true {
            do {
                return try await wrapped.send(method: method, params: params, receive: receive)
            } catch {
                guard Self.isThrottled(error), attempt < maxRetries else {
                    throw error
                }
                // 250ms, 500ms, 1s, 2s, jittered so parallel callers do not retry in lockstep.
                let backoff = UInt64(250_000_000) << UInt64(attempt)
                try? await Task.sleep(nanoseconds: backoff + UInt64.random(in: 0 ... 50_000_000))
                attempt += 1
            }
        }
    }

    /// Best-effort classification. See the type comment for why this is unavoidable and why it
    /// is confined to tests.
    private static func isThrottled(_ error: Error) -> Bool {
        guard let error = error as? JSONRPCError else {
            return false
        }
        switch error {
        case let .executionError(result):
            let text = result.error.message.lowercased()
            return text.contains("too many requests")
                || text.contains("rate limit")
                || text.contains("rate-limit")
                || text.contains("request limit")
                || text.contains("exceeded quota")
                || text.contains("service temporarily unavailable")
        case let .requestRejected(data):
            // A bare HTTP 429 whose body is not a JSON-RPC envelope.
            let text = String(decoding: data, as: UTF8.self).lowercased()
            return text.contains("too many requests") || text.contains("rate limit")
        default:
            return false
        }
    }
}

extension TestConfig {
    /// Builds a client whose requests are retried when the provider throttles them.
    ///
    /// Prefer this over constructing `EthereumHttpClient` directly, so the whole suite shares
    /// one retry policy.
    static func makeClient(url urlString: String, network: EthereumNetwork) -> EthereumClientProtocol {
        guard let url = URL(string: urlString) else {
            fatalError("Invalid test RPC URL: \(urlString)")
        }
        let session = URLSession(configuration: URLSessionConfiguration.ephemeral)
        return BaseEthereumClient(
            networkProvider: RetryingNetworkProvider(
                wrapping: HttpNetworkProvider(session: session, url: url)
            ),
            url: url,
            network: network,
            maxBlockRange: TestConfig.maxBlockRange
        )
    }
}
