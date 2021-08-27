//
//  File.swift
//  File
//
//  Created by Ronald Mannak on 8/25/21.
//

import Foundation
import BigInt

extension ERC20Functions {
    public struct TokenAllowance: ABIFunction {
        public static let name = "allowance"
        public let gasPrice: BigUInt? = nil
        public let gasLimit: BigUInt? = nil
        public var contract: EthereumAddress
        public let from: EthereumAddress? = nil
        
        public let owner: EthereumAddress
        public let spender: EthereumAddress
        
        public init(contract: EthereumAddress,
                    owner: EthereumAddress,
                    spender: EthereumAddress) {
            self.contract = contract
            self.owner = owner
            self.spender = spender
        }
        
        public func encode(to encoder: ABIFunctionEncoder) throws {
            try encoder.encode(owner)
            try encoder.encode(spender)
        }
    }
}
