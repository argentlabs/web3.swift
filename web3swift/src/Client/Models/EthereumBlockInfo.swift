//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation
import BigInt

public struct EthereumBlockInfo: Equatable {
    public var number: EthereumBlock
    public var timestamp: Date
    public var transactions: [String]
    public var gasLimit: BigUInt
    public var gasUsed: BigUInt
    public var baseFeePerGas: BigUInt?
}

extension EthereumBlockInfo: Codable {
    enum CodingKeys: CodingKey {
        case number
        case timestamp
        case transactions
        case gasLimit
        case gasUsed
        case baseFeePerGas
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        guard let number = try? container.decode(EthereumBlock.self, forKey: .number) else {
            throw JSONRPCError.decodingError
        }

        guard let timestampRaw = try? container.decode(String.self, forKey: .timestamp),
              let timestamp = TimeInterval(timestampRaw) else {
            throw JSONRPCError.decodingError
        }

        guard let transactions = try? container.decode([String].self, forKey: .transactions) else {
            throw JSONRPCError.decodingError
        }
        
        guard let gasLimit = try? container.decode(String.self, forKey: .gasLimit) else {
            throw JSONRPCError.decodingError
        }
        
        guard let gasUsed = try? container.decode(String.self, forKey: .gasUsed) else {
            throw JSONRPCError.decodingError
        }
        
        let baseFeePerGas = try? container.decode(String.self, forKey: .baseFeePerGas)

        self.number = number
        self.timestamp = Date(timeIntervalSince1970: timestamp)
        self.transactions = transactions
        self.gasLimit = BigUInt(hex: gasLimit) ?? BigUInt(0)
        self.gasUsed = BigUInt(hex: gasUsed) ?? BigUInt(0)
        if let baseFee = baseFeePerGas {
            self.baseFeePerGas = BigUInt(hex: baseFee)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(number, forKey: .number)
        try container.encode(Int(timestamp.timeIntervalSince1970).web3.hexString, forKey: .timestamp)
        try container.encode(transactions, forKey: .transactions)
        try container.encode(gasLimit.web3.hexString, forKey: .gasLimit)
        try container.encode(gasUsed.web3.hexString, forKey: .gasUsed)
        if let baseFee = baseFeePerGas {
            try container.encode(baseFee.web3.hexString, forKey: .baseFeePerGas)
        }
    }
}
