//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation

public enum EthereumNetwork: Equatable, Decodable {
    case mainnet
    case sepolia
    case custom(String)
    public static func fromString(_ networkId: String) -> EthereumNetwork {
        switch networkId {
        case "1":
            return .mainnet
        case "11155111":
            return .sepolia
        default:
            return .custom(networkId)
        }
    }

    public var stringValue: String {
        switch self {
        case .mainnet:
            return "1"
        case .sepolia:
            return "11155111"
        case let .custom(str):
            return str
        }
    }

    public var intValue: Int {
        switch self {
        case .mainnet:
            return 1
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
