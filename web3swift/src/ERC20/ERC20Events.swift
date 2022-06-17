//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
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
        
        public init?(topics: [ABIDecoder.DecodedValue], data: [ABIDecoder.DecodedValue], log: EthereumLog) throws {
            try Transfer.checkParameters(topics, data)
            self.log = log
            
            self.from = try topics[0].decoded()
            self.to = try topics[1].decoded()
            
            self.value = try data[0].decoded()
        }
    }
}
