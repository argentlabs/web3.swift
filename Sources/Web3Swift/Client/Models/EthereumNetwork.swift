//
//  EthereumNetwork.swift
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
            .mainnet
        case "11155111":
            .sepolia
        default:
            .custom(networkId)
        }
    }

    public var stringValue: String {
        switch self {
        case .mainnet:
            "1"
        case .sepolia:
            "11155111"
        case let .custom(str):
            str
        }
    }

    public var intValue: Int {
        switch self {
        case .mainnet:
            1
        case .sepolia:
            11155111
        case let .custom(str):
            Int(str) ?? 0
        }
    }
}

public func == (lhs: EthereumNetwork, rhs: EthereumNetwork) -> Bool {
    lhs.stringValue == rhs.stringValue
}
