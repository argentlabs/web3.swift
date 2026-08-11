//
//  web3.swift
//  Copyright © Argent Labs Limited. All rights reserved.
//

import BigInt
import Foundation
import XCTest
@testable import web3

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

// MARK: - Stub network provider

private struct ScriptedError: Sendable {
    let code: Int
    let message: String

    static let tooManyResults = ScriptedError(code: -32005, message: "query returned more than 10000 results")
    static let rangeExceeded = ScriptedError(code: -32602, message: "range 20000 exceeds limit of 10000")
    static let invalidParams = ScriptedError(code: -32602, message: "invalid argument 0: hex string has length 39")
    static let generic = ScriptedError(code: -32000, message: "header not found")
}

/// Answers `eth_getLogs` from a scripted block range rather than the network.
///
/// Requests spanning more than `rangeLimit` blocks fail with `overLimitError`; anything
/// narrower returns a single log stamped with its `fromBlock`, so callers can assert on
/// how a query was split and re-aggregated.
private final class StubNetworkProvider: NetworkProviderProtocol, @unchecked Sendable {
    let session = URLSession(configuration: .ephemeral)

    private let rangeLimit: Int
    private let overLimitError: ScriptedError
    private let headBlock: Int
    /// Sub-ranges starting at or above this block fail with `.generic` even when they are
    /// inside the range limit. Expressed as a threshold rather than exact block numbers so
    /// the test does not depend on where the split happens to land.
    private let failFromBlocksAtOrAbove: Int?

    private let lock = NSLock()
    private var _requestedRanges: [ClosedRange<Int>] = []

    init(
        rangeLimit: Int = 10000,
        overLimitError: ScriptedError = .rangeExceeded,
        headBlock: Int = 40000,
        failFromBlocksAtOrAbove: Int? = nil
    ) {
        self.rangeLimit = rangeLimit
        self.overLimitError = overLimitError
        self.headBlock = headBlock
        self.failFromBlocksAtOrAbove = failFromBlocksAtOrAbove
    }

    // Locking lives in synchronous methods: NSLock cannot be taken directly inside an
    // async context, and `withLock` availability differs across platforms.
    var requestedRanges: [ClosedRange<Int>] {
        lock.lock()
        defer { lock.unlock() }
        return _requestedRanges
    }

    private func record(_ range: ClosedRange<Int>) {
        lock.lock()
        defer { lock.unlock() }
        _requestedRanges.append(range)
    }

    func send<P: Encodable, U: Decodable>(method: String, params: P, receive _: U.Type) async throws -> Any {
        switch method {
        case "eth_blockNumber":
            return "0x" + String(headBlock, radix: 16)
        case "eth_getLogs":
            let (from, to) = try decodeRange(params)
            record(from ... max(from, to))

            if to - from > rangeLimit {
                throw jsonRPCError(overLimitError)
            }
            if let threshold = failFromBlocksAtOrAbove, from >= threshold {
                throw jsonRPCError(.generic)
            }
            return [log(atBlock: from)]
        default:
            throw JSONRPCError.noResult
        }
    }

    // MARK: Helpers

    private func jsonRPCError(_ scripted: ScriptedError) -> JSONRPCError {
        .executionError(
            JSONRPCErrorResult(
                id: 1,
                jsonrpc: "2.0",
                error: JSONRPCErrorDetail(code: scripted.code, message: scripted.message, data: nil)
            )
        )
    }

    private func log(atBlock block: Int) -> EthereumLog {
        EthereumLog(
            logIndex: 0,
            transactionIndex: 0,
            transactionHash: "0x\(String(block, radix: 16))",
            blockHash: "0x0",
            blockNumber: EthereumBlock(rawValue: block),
            address: EthereumAddress("0x23d0a442580c01e420270fba6ca836a8b2353acb"),
            data: "0x",
            topics: [],
            removed: false
        )
    }

    /// `eth_getLogs` params encode as `[{fromBlock, toBlock, ...}]`.
    private func decodeRange(_ params: some Encodable) throws -> (Int, Int) {
        let data = try JSONEncoder().encode(params)
        guard
            let array = try JSONSerialization.jsonObject(with: data) as? [Any],
            let filter = array.first as? [String: Any],
            let fromRaw = filter["fromBlock"] as? String,
            let toRaw = filter["toBlock"] as? String
        else {
            throw JSONRPCError.encodingError
        }
        return (try blockNumber(fromRaw), try blockNumber(toRaw))
    }

    private func blockNumber(_ raw: String) throws -> Int {
        switch raw {
        case "earliest": return 0
        case "latest", "pending": return headBlock
        default:
            guard let value = Int(hex: raw) else { throw JSONRPCError.decodingError }
            return value
        }
    }
}

private func makeClient(_ provider: StubNetworkProvider, maxBlockRange: Int? = nil) -> BaseEthereumClient {
    BaseEthereumClient(
        networkProvider: provider,
        url: URL(string: "https://stub.invalid")!,
        network: .mainnet,
        maxBlockRange: maxBlockRange
    )
}

// MARK: - Tests

final class RecursiveLogCollectorTests: XCTestCase {
    /// T1 — the incident. An error the collector cannot handle must surface, never
    /// become an empty result the caller reads as "this wallet has no events".
    func testUnhandledErrorThrowsInsteadOfReturningEmpty() async {
        let provider = StubNetworkProvider(overLimitError: .generic)
        let collector = RecursiveLogCollector(ethClient: makeClient(provider))

        do {
            let logs = try await collector.getAllLogs(
                addresses: nil,
                topics: nil,
                from: EthereumBlock(rawValue: 0),
                to: EthereumBlock(rawValue: 40000)
            )
            XCTFail("Expected a thrown error, got \(logs.count) logs")
        } catch {
            // Expected.
        }
    }

    /// T2 — existing behaviour: `-32005` still triggers the split.
    func testTooManyResultsSplitsAndAggregates() async throws {
        let provider = StubNetworkProvider(overLimitError: .tooManyResults)
        let collector = RecursiveLogCollector(ethClient: makeClient(provider))

        let logs = try await collector.getAllLogs(
            addresses: nil,
            topics: nil,
            from: EthereumBlock(rawValue: 0),
            to: EthereumBlock(rawValue: 40000)
        )

        XCTAssertGreaterThan(logs.count, 1, "Expected the query to be split into several sub-ranges")
        XCTAssertTrue(
            provider.requestedRanges.contains { $0.upperBound - $0.lowerBound <= 10000 },
            "Expected at least one sub-range within the limit"
        )
    }

    /// T3 — with the node's limit declared, the query is fitted to it before being sent.
    /// No error is provoked, so no error has to be recognised.
    func testDeclaredMaxBlockRangeChunksProactively() async throws {
        let provider = StubNetworkProvider(overLimitError: .rangeExceeded)
        let collector = RecursiveLogCollector(ethClient: makeClient(provider, maxBlockRange: 10000))

        let logs = try await collector.getAllLogs(
            addresses: nil,
            topics: nil,
            from: EthereumBlock(rawValue: 0),
            to: EthereumBlock(rawValue: 40000)
        )

        // 0...40000 is 40,001 blocks: four full chunks of 10,000 and a final chunk of one.
        XCTAssertEqual(provider.requestedRanges.count, 5, "No request should be wasted discovering the limit")
        XCTAssertEqual(logs.count, 5)
        XCTAssertTrue(
            provider.requestedRanges.allSatisfy { $0.upperBound - $0.lowerBound + 1 <= 10000 },
            "Every request should already fit the declared limit"
        )
    }

    /// T4 — chunking covers the window exactly: contiguous, no gaps, no overlap.
    func testDeclaredMaxBlockRangeCoversWindowWithoutGapsOrOverlap() async throws {
        let provider = StubNetworkProvider(overLimitError: .rangeExceeded)
        let collector = RecursiveLogCollector(ethClient: makeClient(provider, maxBlockRange: 10000))

        _ = try await collector.getAllLogs(
            addresses: nil,
            topics: nil,
            from: EthereumBlock(rawValue: 100),
            to: EthereumBlock(rawValue: 25000)
        )

        let ranges = provider.requestedRanges.sorted { $0.lowerBound < $1.lowerBound }
        XCTAssertEqual(ranges.first?.lowerBound, 100)
        XCTAssertEqual(ranges.last?.upperBound, 25000)
        for (earlier, later) in zip(ranges, ranges.dropFirst()) {
            XCTAssertEqual(later.lowerBound, earlier.upperBound + 1, "Chunks must be contiguous")
        }
    }

    /// T5 — `.Earliest`/`.Latest` resolve to concrete bounds before chunking.
    func testDeclaredMaxBlockRangeResolvesSymbolicBounds() async throws {
        let provider = StubNetworkProvider(overLimitError: .rangeExceeded)
        let collector = RecursiveLogCollector(ethClient: makeClient(provider, maxBlockRange: 10000))

        let logs = try await collector.getAllLogs(addresses: nil, topics: nil, from: .Earliest, to: .Latest)

        XCTAssertGreaterThan(logs.count, 1, "Expected .Earliest/.Latest to resolve rather than fail")
        XCTAssertTrue(provider.requestedRanges.allSatisfy { $0.upperBound - $0.lowerBound + 1 <= 10000 })
    }

    /// T6 — without a declared limit, a range rejection is no longer guessed at from its
    /// message. It surfaces, carrying the node's own code and text.
    func testRangeErrorSurfacesWhenNoLimitDeclared() async {
        let provider = StubNetworkProvider(overLimitError: .rangeExceeded)
        let collector = RecursiveLogCollector(ethClient: makeClient(provider))

        do {
            let logs = try await collector.getAllLogs(
                addresses: nil,
                topics: nil,
                from: EthereumBlock(rawValue: 0),
                to: EthereumBlock(rawValue: 40000)
            )
            XCTFail("Expected a thrown error, got \(logs.count) logs")
        } catch {
            XCTAssertEqual(provider.requestedRanges.count, 1, "Expected no recursion without a declared limit")
        }
    }

    /// T7 — a genuinely malformed request surfaces immediately.
    func testInvalidParamsErrorThrowsWithoutRecursing() async {
        let provider = StubNetworkProvider(overLimitError: .invalidParams)
        let collector = RecursiveLogCollector(ethClient: makeClient(provider))

        do {
            let logs = try await collector.getAllLogs(
                addresses: nil,
                topics: nil,
                from: EthereumBlock(rawValue: 0),
                to: EthereumBlock(rawValue: 40000)
            )
            XCTFail("Expected a thrown error, got \(logs.count) logs")
        } catch {
            XCTAssertEqual(provider.requestedRanges.count, 1, "Expected no recursion on a malformed request")
        }
    }

    /// T8 — a failure inside one half of a split must propagate, not be swallowed by `try?`.
    func testFailureWithinSplitPropagates() async {
        // The left half of the split succeeds; anything in the upper quarter fails.
        let provider = StubNetworkProvider(overLimitError: .tooManyResults, failFromBlocksAtOrAbove: 30000)
        let collector = RecursiveLogCollector(ethClient: makeClient(provider))

        do {
            let logs = try await collector.getAllLogs(
                addresses: nil,
                topics: nil,
                from: EthereumBlock(rawValue: 0),
                to: EthereumBlock(rawValue: 40000)
            )
            XCTFail("Expected the sub-range failure to propagate, got \(logs.count) logs")
        } catch {
            // Expected.
        }
    }
}
