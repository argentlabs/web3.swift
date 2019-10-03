//
//  EthereumBlockData.swift
//  web3swift
//
//  Created by Miguel on 11/06/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation

public struct EthereumBlockInfo: Equatable {
    public var number: EthereumBlock
    public var timestamp: Date
    public var transactions: [String]
}

extension EthereumBlockInfo: Codable {
    enum CodingKeys: CodingKey {
        case number
        case timestamp
        case transactions
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
        
        self.number = number
        self.timestamp = Date(timeIntervalSince1970: timestamp)
        self.transactions = transactions
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(number, forKey: .number)
        try container.encode(Int(timestamp.timeIntervalSince1970).web3.hexString, forKey: .timestamp)
        try container.encode(transactions, forKey: .transactions)
    }
}

