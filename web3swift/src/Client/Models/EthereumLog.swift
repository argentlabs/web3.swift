//
//  EthereumLog.swift
//  web3swift
//
//  Created by Matt Marshall on 09/03/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation
import BigInt

public struct EthereumLog: Decodable {
    public let logIndex: BigUInt?
    public let transactionIndex: BigUInt?
    public let transactionHash: String?
    public let blockHash: String?
    public let blockNumber: BigUInt?
    public let address: String
    public var data: String
    public var topics: Array<String>
    public let removed: Bool
    
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
        
        self.removed = try values.decode(Bool.self, forKey: .removed)
        self.address = try values.decode(String.self, forKey: .address)
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
        
        if let transactionHash = try? values.decode(String.self, forKey: .transactionHash) {
            self.transactionHash = transactionHash
        } else {
            self.transactionHash = nil
        }
        
        if let blockHash = try? values.decode(String.self, forKey: .blockHash) {
            self.blockHash = blockHash
        } else {
            self.blockHash = nil
        }
        
        if let blockNumberString = try? values.decode(String.self, forKey: .blockNumber), let blockNumber = BigUInt(hex: blockNumberString) {
            self.blockNumber = blockNumber
        } else {
            self.blockNumber = nil
        }
    }
}

