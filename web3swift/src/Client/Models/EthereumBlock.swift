//
//  web3.swift
//  Copyright © Argent Labs Limited. All rights reserved.
//

import Foundation

public enum EthereumBlock: Sendable, Hashable {
    case Latest
    case Earliest
    case Pending
    case Number(Int)

    public var stringValue: String {
        switch self {
        case .Latest:
            "latest"
        case .Earliest:
            "earliest"
        case .Pending:
            "pending"
        case let .Number(int):
            int.web3.hexString
        }
    }

    public var intValue: Int? {
        switch self {
        case let .Number(int):
            int
        default:
            nil
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
        try container.encode(stringValue)
    }
}

extension EthereumBlock: Comparable {
    static public func == (lhs: EthereumBlock, rhs: EthereumBlock) -> Bool {
        lhs.stringValue == rhs.stringValue
    }

    static public func < (lhs: EthereumBlock, rhs: EthereumBlock) -> Bool {
        switch lhs {
        case .Earliest:
            false
        case .Latest:
            rhs != .Pending ? true : false
        case .Pending:
            true
        case let .Number(lhsInt):
            switch rhs {
            case .Earliest:
                false
            case .Latest:
                true
            case .Pending:
                true
            case let .Number(rhsInt):
                lhsInt < rhsInt
            }
        }
    }
}
