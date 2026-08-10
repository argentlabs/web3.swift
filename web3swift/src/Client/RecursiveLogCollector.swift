//
//  web3.swift
//  Copyright © Argent Labs Limited. All rights reserved.
//

import Foundation

public enum Topics: Encodable {
    case plain([String?])
    case composed([[String]?])

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        switch self {
        case let .plain(values):
            try container.encode(contentsOf: values)
        case let .composed(values):
            try container.encode(contentsOf: values)
        }
    }
}

struct RecursiveLogCollector {
    let ethClient: EthereumRPCProtocol

    func getAllLogs(addresses: [EthereumAddress]?, topics: Topics?, from: EthereumBlock, to: EthereumBlock) async throws -> [EthereumLog] {
        // When the node's limit is known, fit the query to it up front. That needs no error
        // classification at all, and costs no failed request to discover the boundary.
        if let maxBlockRange = ethClient.maxBlockRange,
           let chunked = try await collectInChunks(
               addresses: addresses,
               topics: topics,
               from: from,
               to: to,
               maxBlockRange: maxBlockRange
           ) {
            return chunked
        }

        do {
            return try await getLogs(addresses: addresses, topics: topics, from: from, to: to)
        } catch let error as EthereumClientError where error == .tooManyResults {
            // Fallback for callers that have not declared a limit. `-32005` is the only
            // structural hint a node gives, and it is ambiguous — some providers reuse it for
            // rate limiting, where splitting makes things worse. Set `maxBlockRange` to avoid
            // relying on it.
            return try await splitAndCollect(addresses: addresses, topics: topics, from: from, to: to)
        }
        // Any other error propagates. Returning an empty array here would be
        // indistinguishable from "this range genuinely contains no logs".
    }

    /// Splits the window into spans no wider than the node accepts and concatenates the results.
    ///
    /// Returns `nil` when the bounds cannot be resolved to concrete numbers, leaving the caller
    /// to send the query unchunked.
    private func collectInChunks(
        addresses: [EthereumAddress]?,
        topics: Topics?,
        from: EthereumBlock,
        to: EthereumBlock,
        maxBlockRange: Int
    ) async throws -> [EthereumLog]? {
        guard
            maxBlockRange > 0,
            let fromBlock = await resolveBlockNumber(from),
            let toBlock = await resolveBlockNumber(to) else {
            return nil
        }
        guard fromBlock <= toBlock else {
            return []
        }

        var logs: [EthereumLog] = []
        var start = fromBlock
        while start <= toBlock {
            // `maxBlockRange` counts blocks inclusive of both bounds, so a limit of 10,000
            // permits `from...from + 9_999`. Providers word their caps that way, and being one
            // block over is enough to be rejected.
            let end = min(start + maxBlockRange - 1, toBlock)
            logs += try await getLogs(
                addresses: addresses,
                topics: topics,
                from: EthereumBlock(rawValue: start),
                to: EthereumBlock(rawValue: end)
            )
            start = end + 1
        }
        return logs
    }

    /// Halves the range and collects both sides. Only called for errors that narrowing can fix.
    private func splitAndCollect(
        addresses: [EthereumAddress]?,
        topics: Topics?,
        from: EthereumBlock,
        to: EthereumBlock
    ) async throws -> [EthereumLog] {
        guard
            let fromBlock = await resolveBlockNumber(from),
            let toBlock = await resolveBlockNumber(to),
            // Below two blocks there is nothing left to halve, so recursing would not
            // terminate. Surface the original error instead.
            toBlock - fromBlock >= 2 else {
            throw EthereumClientError.tooManyResults
        }

        let middle = fromBlock + (toBlock - fromBlock) / 2

        let lhs = try await getAllLogs(
            addresses: addresses,
            topics: topics,
            from: EthereumBlock(rawValue: fromBlock),
            to: EthereumBlock(rawValue: middle)
        )
        let rhs = try await getAllLogs(
            addresses: addresses,
            topics: topics,
            // Start after `middle`; both halves including it would duplicate its logs.
            from: EthereumBlock(rawValue: middle + 1),
            to: EthereumBlock(rawValue: toBlock)
        )
        return lhs + rhs
    }

    /// Resolves a block to a concrete number so the range can be halved.
    /// `.Earliest` is block zero; `.Latest` and `.Pending` resolve to the current head.
    private func resolveBlockNumber(_ block: EthereumBlock) async -> Int? {
        if let number = block.intValue {
            return number
        }
        if block == .Earliest {
            return 0
        }
        return try? await ethClient.eth_blockNumber()
    }

    private func getLogs(addresses: [EthereumAddress]?, topics: Topics? = nil, from: EthereumBlock, to: EthereumBlock) async throws -> [EthereumLog] {
        try await ethClient.getLogs(addresses: addresses, topics: topics, fromBlock: from, toBlock: to)
    }
}
