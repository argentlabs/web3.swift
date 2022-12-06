//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
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
    let ethClient: EthereumClientProtocol

    func getAllLogs(addresses: [EthereumAddress]?, topics: Topics?, from: EthereumBlock, to: EthereumBlock) async throws -> [EthereumLog] {
        do {
            return try await getLogs(addresses: addresses, topics: topics, from: from, to: to)
        } catch {
            if let error = error as? EthereumClientError, error == .tooManyResults {
                guard let middleBlock = await getMiddleBlock(from: from, to: to) else {
                    throw EthereumClientError.unexpectedReturnValue
                }

                guard let lhs = try? await getAllLogs(addresses: addresses, topics: topics, from: from, to: middleBlock),
                      let rhs = try? await getAllLogs(addresses: addresses, topics: topics, from: middleBlock, to: to) else {
                    throw EthereumClientError.unexpectedReturnValue
                }
                return lhs + rhs
            }
        }
        return []
    }

    private func getLogs(addresses: [EthereumAddress]?, topics: Topics? = nil, from: EthereumBlock, to: EthereumBlock) async throws -> [EthereumLog] {
        try await ethClient.getLogs(addresses: addresses, topics: topics, fromBlock: from, toBlock: to)
    }

    private func getMiddleBlock(from: EthereumBlock, to: EthereumBlock) async -> EthereumBlock? {
        func toBlockNumber() async -> Int? {
            if let toBlockNumber = to.intValue {
                return toBlockNumber
            } else if let currentBlock = try? await getCurrentBlock(), let currentBlockNumber = currentBlock.intValue {
                return currentBlockNumber
            } else {
                return nil
            }
        }

        guard let fromBlockNumber = from.intValue, let toBlockNumber = await toBlockNumber() else {
            return nil
        }

        return EthereumBlock(rawValue: fromBlockNumber + (toBlockNumber - fromBlockNumber) / 2)
    }

    private func getCurrentBlock() async throws -> EthereumBlock {
        do {
            let block = try await ethClient.eth_blockNumber()
            return EthereumBlock(rawValue: block)
        } catch {
            throw EthereumClientError.unexpectedReturnValue
        }
    }
}
