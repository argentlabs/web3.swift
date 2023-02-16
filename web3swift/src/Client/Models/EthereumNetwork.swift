//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation

public enum EthereumNetwork: Equatable, Decodable {
    case mainnet
    case kovan
    case goerli
    case sepolia
    case custom(String)
    static func fromString(_ networkId: String) -> EthereumNetwork {
        switch networkId {
        case "1":
            return .mainnet
        case "5":
            return .goerli
        case "42":
            return .kovan
        case "11155111":
            return .sepolia
        default:
            return .custom(networkId)
        }
    }

    var stringValue: String {
        switch self {
        case .mainnet:
            return "1"
        case .goerli:
            return "5"
        case .kovan:
            return "42"
        case .sepolia:
            return "11155111"
        case let .custom(str):
            return str
        }
    }

    var intValue: Int {
        switch self {
        case .mainnet:
            return 1
        case .goerli:
            return 5
        case .kovan:
            return 42
        case .sepolia:
            return 11155111
        case let .custom(str):
            return Int(str) ?? 0
        }
    }
}

public func == (lhs: EthereumNetwork, rhs: EthereumNetwork) -> Bool {
    lhs.stringValue == rhs.stringValue
}
