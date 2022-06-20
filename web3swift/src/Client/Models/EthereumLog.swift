//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import BigInt
import Foundation

public struct EthereumLog: Equatable {
    public let logIndex: BigUInt?
    public let transactionIndex: BigUInt?
    public let transactionHash: String?
    public let blockHash: String?
    public let blockNumber: EthereumBlock
    public let address: EthereumAddress
    public var data: String
    public var topics: [String]
    public let removed: Bool?
}

extension EthereumLog: Codable {
    enum CodingKeys: String, CodingKey {
        case removed            // Bool
        case logIndex           // Quantity or null
        case transactionIndex   // Quantity or null
        case transactionHash    // Data or null
        case blockHash          // Data or null
        case blockNumber        // Data or null
        case address            // Data
        case data               // Data
        case topics             // Array of Data
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        self.removed = try values.decodeIfPresent(Bool.self, forKey: .removed)
        self.address = try values.decode(EthereumAddress.self, forKey: .address)
        self.data = try values.decode(String.self, forKey: .data)
        self.topics = try values.decode([String].self, forKey: .topics)

        if let logIndexString = try? values.decode(String.self, forKey: .logIndex), let logIndex = BigUInt(hex: logIndexString) {
            self.logIndex = logIndex
        } else {
            self.logIndex = nil
        }

        if let transactionIndexString = try? values.decode(String.self, forKey: .transactionIndex), let transactionIndex = BigUInt(hex: transactionIndexString) {
            self.transactionIndex = transactionIndex
        } else {
            self.transactionIndex = nil
        }

        self.transactionHash = try? values.decode(String.self, forKey: .transactionHash)
        self.blockHash = try? values.decode(String.self, forKey: .blockHash)

        if let blockNumberString = try? values.decode(String.self, forKey: .blockNumber) {
            self.blockNumber = EthereumBlock(rawValue: blockNumberString)
        } else {
            self.blockNumber = EthereumBlock.Earliest
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(removed, forKey: .removed)
        if let bytes = logIndex?.web3.bytes {
            try? container.encode(String(bytes: bytes).web3.withHexPrefix, forKey: .logIndex)
        }
        if let bytes = transactionIndex?.web3.bytes {
            try? container.encode(String(bytes: bytes).web3.withHexPrefix, forKey: .transactionIndex)
        }
        try? container.encode(transactionHash, forKey: .transactionHash)
        try? container.encode(blockHash, forKey: .blockHash)
        try container.encode(blockNumber.stringValue, forKey: .blockNumber)
        try container.encode(address, forKey: .address)
        try container.encode(data, forKey: .data)
        try container.encode(topics, forKey: .topics)

    }

}

extension EthereumLog: Comparable {
    public static func < (lhs: EthereumLog, rhs: EthereumLog) -> Bool {
        if lhs.blockNumber == rhs.blockNumber,
            let lhsIndex = lhs.logIndex,
            let rhsIndex = rhs.logIndex {
            return lhsIndex < rhsIndex
        }

        return lhs.blockNumber < rhs.blockNumber
    }
}
