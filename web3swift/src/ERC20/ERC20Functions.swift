//
//  ERC20Functions.swift
//  web3swift
//
//  Created by Matt Marshall on 13/04/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation
import BigInt

public enum ERC20Functions {
    public struct name: ABIFunction {
        public static let name = "name"
        public let gasPrice: BigUInt? = nil
        public let gasLimit: BigUInt? = nil
        public var contract: EthereumAddress
        public let from: EthereumAddress? = nil
        
        public func encode(to encoder: ABIFunctionEncoder) throws {
        }
    }
    
    public struct symbol: ABIFunction {
        public static let name = "symbol"
        public let gasPrice: BigUInt? = nil
        public let gasLimit: BigUInt? = nil
        public var contract: EthereumAddress
        public let from: EthereumAddress? = nil
        
        public func encode(to encoder: ABIFunctionEncoder) throws { }
    }
    
    public struct decimals: ABIFunction {
        public static let name = "decimals"
        public let gasPrice: BigUInt? = nil
        public let gasLimit: BigUInt? = nil
        public var contract: EthereumAddress
        public let from: EthereumAddress? = nil
        
        public func encode(to encoder: ABIFunctionEncoder) throws { }
    }
    
    public struct balanceOf: ABIFunction {
        public static let name = "balanceOf"
        public let gasPrice: BigUInt? = nil
        public let gasLimit: BigUInt? = nil
        public var contract: EthereumAddress
        public let account: EthereumAddress
        public let from: EthereumAddress? = nil
        
        public func encode(to encoder: ABIFunctionEncoder) throws {
            try encoder.encode(account)
        }
    }
}

