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
        case .plain(let values):
            try container.encode(contentsOf: values)
        case .composed(let values):
            try container.encode(contentsOf: values)
        }
    }
}

struct RecursiveLogCollector {
    let ethClient: EthereumClientProtocol

    func getAllLogs(
        addresses: [EthereumAddress]?,
        topics: Topics?,
        from: EthereumBlock,
        to: EthereumBlock
    ) -> Result<[EthereumLog], EthereumClientError> {

        switch getLogs(addresses: addresses, topics: topics, from: from, to: to) {
        case .success(let logs):
            return .success(logs)
        case.failure(.tooManyResults):
            guard let middleBlock = getMiddleBlock(from: from, to: to)
                else { return .failure(.unexpectedReturnValue) }

            guard
                case let .success(lhs) = getAllLogs(
                    addresses: addresses,
                    topics: topics,
                    from: from,
                    to: middleBlock
                ),
                case let .success(rhs) = getAllLogs(
                    addresses: addresses,
                    topics: topics,
                    from: middleBlock,
                    to: to
                )
            else { return .failure(.unexpectedReturnValue) }

            return .success(lhs + rhs)
        case .failure(let error):
            return .failure(error)
        }
    }

    private func getLogs(
        addresses: [EthereumAddress]?,
        topics: Topics? = nil,
        from: EthereumBlock,
        to: EthereumBlock
    ) -> Result<[EthereumLog], EthereumClientError> {

        let sem = DispatchSemaphore(value: 0)

        var response: Result<[EthereumLog], EthereumClientError>!

        ethClient.getLogs(addresses: addresses, topics: topics, fromBlock: from, toBlock: to) { result in
            response = result
            sem.signal()
        }

        sem.wait()

        return response
    }

    private func getMiddleBlock(
        from: EthereumBlock,
        to: EthereumBlock
    ) -> EthereumBlock? {

        func toBlockNumber() -> Int? {
            if let toBlockNumber = to.intValue {
                return toBlockNumber
            } else if case let .success(currentBlock) = getCurrentBlock(), let currentBlockNumber = currentBlock.intValue {
                return currentBlockNumber
            } else {
                return nil
            }
        }

        guard
            let fromBlockNumber = from.intValue,
            let toBlockNumber = toBlockNumber()
        else { return nil }

        return EthereumBlock(rawValue: fromBlockNumber + (toBlockNumber - fromBlockNumber) / 2)
    }

    private func getCurrentBlock() -> Result<EthereumBlock, EthereumClientError> {
        let sem = DispatchSemaphore(value: 0)
        var responseValue: EthereumBlock?

        self.ethClient.eth_blockNumber { result in
            switch result {
            case .success(let block):
                responseValue = EthereumBlock(rawValue: block)
            default:
                break
            }
            sem.signal()
        }
        sem.wait()

        return responseValue.map(Result.success) ?? .failure(.unexpectedReturnValue)
    }
}
