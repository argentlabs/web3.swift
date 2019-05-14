//
//  ERC721Events.swift
//  web3swift
//
//  Created by Miguel on 09/05/2019.
//  Copyright © 2019 Argent Labs Limited. All rights reserved.
//

import Foundation
import BigInt

public enum ERC721Events {
    public struct Transfer: ABIEvent {
        public static let name = "Transfer"
        public static let types: [ABIType.Type] = [ EthereumAddress.self , EthereumAddress.self , BigUInt.self]
        public static let typesIndexed = [true, true, true]
        public let log: EthereumLog
        
        public let from: EthereumAddress
        public let to: EthereumAddress
        public let tokenId: BigUInt
        
        public init?(topics: [String], data: [String], log: EthereumLog) throws {
            try Transfer.checkParameters(topics, data)
            self.log = log
            
            self.from = try ABIDecoder.decode(topics[0], to: EthereumAddress.self)
            self.to = try ABIDecoder.decode(topics[1], to: EthereumAddress.self)
            self.tokenId = try ABIDecoder.decode(topics[2], to: BigUInt.self)
        }
    }
    
    public struct Approval: ABIEvent {
        public static let name = "Approval"
        public static let types: [ABIType.Type] = [ EthereumAddress.self , EthereumAddress.self , BigUInt.self]
        public static let typesIndexed = [true, true, true]
        public let log: EthereumLog
        
        public let from: EthereumAddress
        public let approved: EthereumAddress
        public let tokenId: BigUInt
        
        public init?(topics: [String], data: [String], log: EthereumLog) throws {
            try Approval.checkParameters(topics, data)
            self.log = log
            
            self.from = try ABIDecoder.decode(topics[0], to: EthereumAddress.self)
            self.approved = try ABIDecoder.decode(topics[1], to: EthereumAddress.self)
            self.tokenId = try ABIDecoder.decode(topics[2], to: BigUInt.self)
        }
    }
    
    public struct ApprovalForAll: ABIEvent {
        public static let name = "ApprovalForAll"
        public static let types: [ABIType.Type] = [ EthereumAddress.self , EthereumAddress.self , BigUInt.self]
        public static let typesIndexed = [true, true, true]
        public let log: EthereumLog
        
        public let from: EthereumAddress
        public let `operator`: EthereumAddress
        public let approved: Bool
        
        public init?(topics: [String], data: [String], log: EthereumLog) throws {
            try ApprovalForAll.checkParameters(topics, data)
            self.log = log
            
            self.from = try ABIDecoder.decode(topics[0], to: EthereumAddress.self)
            self.operator = try ABIDecoder.decode(topics[1], to: EthereumAddress.self)
            self.approved = try ABIDecoder.decode(topics[2], to: Bool.self)
        }
    }
}
