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
        public let from: EthereumAddress?
        
        public init(contract: EthereumAddress,
                    from: EthereumAddress? = nil) {
            self.contract = contract
            self.from = from
        }
        
        public func encode(to encoder: ABIFunctionEncoder) throws {
        }
    }
    
    public struct symbol: ABIFunction {
        public static let name = "symbol"
        public let gasPrice: BigUInt? = nil
        public let gasLimit: BigUInt? = nil
        public var contract: EthereumAddress
        public let from: EthereumAddress?
        
        public init(contract: EthereumAddress,
                    from: EthereumAddress? = nil) {
            self.contract = contract
            self.from = from
        }
        
        public func encode(to encoder: ABIFunctionEncoder) throws { }
    }
    
    public struct decimals: ABIFunction {
        public static let name = "decimals"
        public let gasPrice: BigUInt? = nil
        public let gasLimit: BigUInt? = nil
        public var contract: EthereumAddress
        public let from: EthereumAddress?
        
        public init(contract: EthereumAddress,
                    from: EthereumAddress? = nil) {
            self.contract = contract
            self.from = from
        }
        
        public func encode(to encoder: ABIFunctionEncoder) throws { }
    }
    
    public struct balanceOf: ABIFunction {
        public static let name = "balanceOf"
        public let gasPrice: BigUInt? = nil
        public let gasLimit: BigUInt? = nil
        public var contract: EthereumAddress
        public let account: EthereumAddress
        public let from: EthereumAddress?
        
        public init(contract: EthereumAddress,
                    from: EthereumAddress? = nil,
                    account: EthereumAddress) {
            self.contract = contract
            self.from = from
            self.account = account
        }
        
        public func encode(to encoder: ABIFunctionEncoder) throws {
            try encoder.encode(account)
        }
    }
    
    public struct allowance: ABIFunction {
        public static let name = "allowance"
        public let gasPrice: BigUInt? = nil
        public let gasLimit: BigUInt? = nil
        public var contract: EthereumAddress
        public let owner: EthereumAddress
        public let spender: EthereumAddress
        public let from: EthereumAddress?
        
        public init(contract: EthereumAddress,
                    from: EthereumAddress? = nil,
                    owner: EthereumAddress,
                    spender: EthereumAddress) {
            self.contract = contract
            self.from = from
            self.owner = owner
            self.spender = spender
        }
        
        public func encode(to encoder: ABIFunctionEncoder) throws {
            try encoder.encode(owner)
            try encoder.encode(spender)
        }
    }
    
    public struct approve: ABIFunction {
        public static let name = "approve"
        public let gasPrice: BigUInt? = nil
        public let gasLimit: BigUInt? = nil
        public var contract: EthereumAddress
        public let from: EthereumAddress?
        
        public let spender: EthereumAddress
        public let value: BigUInt
        
        public init(contract: EthereumAddress,
                    from: EthereumAddress? = nil,
                    spender: EthereumAddress,
                    value: BigUInt) {
            self.contract = contract
            self.from = from
            self.spender = spender
            self.value = value
        }

        public func encode(to encoder: ABIFunctionEncoder) throws {
            try encoder.encode(spender)
            try encoder.encode(value)
        }
    }
    
    public struct transfer: ABIFunction {
        public static let name = "transfer"
        public let gasPrice: BigUInt? = nil
        public let gasLimit: BigUInt? = nil
        public var contract: EthereumAddress
        public let from: EthereumAddress?
        
        public let to: EthereumAddress
        public let value: BigUInt
        
        public init(contract: EthereumAddress,
                    from: EthereumAddress? = nil,
                    to: EthereumAddress,
                    value: BigUInt) {
            self.contract = contract
            self.from = from
            self.to = to
            self.value = value
        }
        
        public func encode(to encoder: ABIFunctionEncoder) throws {
            try encoder.encode(to)
            try encoder.encode(value)
        }
    }
    
    public struct transferFrom: ABIFunction {
        public static let name = "transferFrom"
        public let gasPrice: BigUInt? = nil
        public let gasLimit: BigUInt? = nil
        public var contract: EthereumAddress
        public let from: EthereumAddress?
        
        public let sender: EthereumAddress
        public let to: EthereumAddress
        public let value: BigUInt
        
        public init(contract: EthereumAddress,
                    from: EthereumAddress? = nil,
                    sender: EthereumAddress,
                    to: EthereumAddress,
                    value: BigUInt) {
            self.contract = contract
            self.from = from
            self.sender = sender
            self.to = to
            self.value = value
        }
        
        public func encode(to encoder: ABIFunctionEncoder) throws {
            try encoder.encode(sender)
            try encoder.encode(to)
            try encoder.encode(value)
        }
    }
}

