//
//  EthereumBlock.swift
//  web3swift
//
//  Created by Matt Marshall on 20/03/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation

public enum EthereumBlock {
    case Latest
    case Earliest
    case Pending
    case Number(Int)
    
    public var stringValue: String {
        switch self {
        case .Latest:
            return "latest"
        case .Earliest:
            return "earliest"
        case .Pending:
            return "pending"
        case .Number(let int):
            return int.hexString
        }
    }
    
    public var intValue: Int? {
        switch self {
        case .Number(let int):
            return int
        default:
            return nil
        }
    }
    
    public init(rawValue: Int) {
        self = .Number(rawValue)
    }
    
    public init(rawValue: String) {
        if rawValue == "latest" {
            self = .Latest
        } else if rawValue == "earliest" {
            self = .Earliest
        } else if rawValue == "pending" {
            self = .Pending
        } else {
            self = .Number(Int(hex: rawValue) ?? 0)
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
        case .Earliest:
            return false
        case .Latest:
            return rhs != .Pending ? true : false
        case .Pending:
            return true
        case .Number(let lhsInt):
            switch rhs {
            case .Earliest:
                return false
            case .Latest:
                return true
            case .Pending:
                return true
            case .Number(let rhsInt):
                return lhsInt < rhsInt
            }
        }
        
    }
}
