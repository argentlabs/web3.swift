//
//  ERC20Events.swift
//  web3swift
//
//  Created by Matt Marshall on 25/04/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation
import BigInt

public enum ERC20Events {
    public struct Transfer: ABIEvent {
        public static let name = "Transfer"
        public static let types: [ABIType.Type] = [ EthereumAddress.self , EthereumAddress.self , BigUInt.self]
        public static let typesIndexed = [true, true, false]
        public let log: EthereumLog
        
        public let from: EthereumAddress
        public let to: EthereumAddress
        public let value: BigUInt
        
        public init?(topics: [String], data: [ABIType], log: EthereumLog) throws {
            try Transfer.checkParameters(topics, data)
            self.log = log
            
            self.from = try ABIDecoder.decode(topics[0], to: EthereumAddress.self)
            self.to = try ABIDecoder.decode(topics[1], to: EthereumAddress.self)
            
            guard let valueStr = data[0] as? String else { return nil }
            self.value = try ABIDecoder.decode(valueStr, to: BigUInt.self)
        }
    }
}
