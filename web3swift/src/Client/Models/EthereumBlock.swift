//
//  EthereumBlock.swift
//  web3swift
//
//  Created by Matt Marshall on 20/03/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation

public enum EthereumBlock: Hashable {
    case latest
    case earliest
    case pending
    case number(Int)
    
    public var stringValue: String {
        switch self {
        case .latest:
            return "latest"
        case .earliest:
            return "earliest"
        case .pending:
            return "pending"
        case .number(let int):
            return int.web3.hexString
        }
    }
    
    public var intValue: Int? {
        switch self {
        case .number(let int):
            return int
        default:
            return nil
        }
    }
    
    public init(rawValue: Int) {
        self = .number(rawValue)
    }
    
    public init(rawValue: String) {
        if rawValue == "latest" {
            self = .latest
        } else if rawValue == "earliest" {
            self = .earliest
        } else if rawValue == "pending" {
            self = .pending
        } else {
            self = .number(Int(hex: rawValue) ?? 0)
        }
    }
}

extension EthereumBlock: Codable {
    public init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer()
        let strValue = try value.decode(String.self)
        self = EthereumBlock(rawValue: strValue)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.stringValue)
    }
}

extension EthereumBlock: Comparable {
    static public func == (lhs: EthereumBlock, rhs: EthereumBlock) -> Bool {
        return lhs.stringValue == rhs.stringValue
    }
    
    static public func < (lhs: EthereumBlock, rhs: EthereumBlock) -> Bool {
        switch lhs {
        case .earliest:
            return false
        case .latest:
            return rhs != .pending ? true : false
        case .pending:
            return true
        case .number(let lhsInt):
            switch rhs {
            case .earliest:
                return false
            case .latest:
                return true
            case .pending:
                return true
            case .number(let rhsInt):
                return lhsInt < rhsInt
            }
        }
        
    }
}
