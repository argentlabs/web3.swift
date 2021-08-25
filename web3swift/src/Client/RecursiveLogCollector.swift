//
//  RecursiveLogCollector.swift
//  web3swift
//
//  Created by David Rodrigues on 05/01/2021.
//  Copyright © 2021 Argent Labs Limited. All rights reserved.
//

import Foundation

enum Topics: Encodable {
    case plain([String?])
    case composed([[String]?])

    func encode(to encoder: Encoder) throws {
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
    let ethClient: EthereumClient

    @available(*, deprecated, message: "Prefer async alternative instead")
    func getAllLogs(
        addresses: [EthereumAddress]?,
        topics: Topics?,
        from: EthereumBlock,
        to: EthereumBlock
    ) -> Result<[EthereumLog], Web3Error> {

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
    
    func getAllLogs(
        addresses: [EthereumAddress]?,
        topics: Topics?,
        from: EthereumBlock,
        to: EthereumBlock
    ) async throws -> [EthereumLog] {

        do {
            return try await getLogs(addresses: addresses, topics: topics, from: from, to: to)
        } catch Web3Error.tooManyResults {
            
            guard let middleBlock = await getMiddleBlock(from: from, to: to) else {
                throw Web3Error.unexpectedReturnValue
            }
            
            guard let lhs = try? await getAllLogs(addresses: addresses, topics: topics, from: from, to: middleBlock),
                  let rhs = try? await getAllLogs(addresses: addresses, topics: topics, from: middleBlock, to: to) else {
                
                      throw Web3Error.unexpectedReturnValue
                      
            }
            return lhs+rhs
        }
    }
    
    @available(*, deprecated, message: "Prefer async alternative instead")
    private func getLogs(
        addresses: [EthereumAddress]?,
        topics: Topics? = nil,
        from: EthereumBlock,
        to: EthereumBlock
    ) -> Result<[EthereumLog], Web3Error> {

        let sem = DispatchSemaphore(value: 0)

        var response: Result<[EthereumLog], Web3Error>!

        ethClient.getLogs(addresses: addresses, topics: topics, fromBlock: from, toBlock: to) { result in
            response = result
            sem.signal()
        }

        sem.wait()

        return response
    }
    
    private func getLogs(
        addresses: [EthereumAddress]?,
        topics: Topics? = nil,
        from: EthereumBlock,
        to: EthereumBlock
    ) async throws -> [EthereumLog] {
        
        return try await ethClient.getLogs(addresses: addresses, topics: topics, fromBlock: from, toBlock: to)
    }

    @available(*, deprecated, message: "Prefer async alternative instead")
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
    
    private func getMiddleBlock(
        from: EthereumBlock,
        to: EthereumBlock
    ) async -> EthereumBlock? {

        guard let fromBlockNumber = from.intValue else { return nil }
            
        let toBlockNumber: Int
        do {
            if let toBlock = to.intValue {
                toBlockNumber = toBlock
            } else if let toBlock = try await getCurrentBlock().intValue {
                toBlockNumber = toBlock
            } else {
                return nil
            }
        } catch {
            return nil
        }

        return EthereumBlock(rawValue: fromBlockNumber + (toBlockNumber - fromBlockNumber) / 2)
    }
    
    @available(*, deprecated, message: "Prefer async alternative instead")
    private func getCurrentBlock() -> Result<EthereumBlock, Web3Error> {
        let sem = DispatchSemaphore(value: 0)
        var responseValue: EthereumBlock?

        self.ethClient.eth_blockNumber { (error, blockInt) in
            if let blockInt = blockInt {
                responseValue = EthereumBlock(rawValue: blockInt)
            }
            sem.signal()
        }
        sem.wait()

        return responseValue.map(Result.success) ?? .failure(.unexpectedReturnValue)
    }
    
    private func getCurrentBlock() async throws -> EthereumBlock {
        let blockInt = try await self.ethClient.eth_blockNumber()
        return EthereumBlock(rawValue: blockInt)
    }
}
