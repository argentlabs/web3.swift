//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation

public enum EthereumNetwork: Equatable {
    case mainnet
    case ropsten
    case rinkeby
    case kovan
    case goerli
    case sepolia
    case custom(String)
    
    static func fromString(_ networkId: String) -> EthereumNetwork {
        switch networkId {
        case "1":
            return .mainnet
        case "3":
            return .ropsten
        case "4":
            return .rinkeby
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
        case .ropsten:
            return "3"
        case .rinkeby:
            return "4"
        case .goerli:
            return "5"
        case .kovan:
            return "42"
        case .sepolia:
            return "11155111"
        case .custom(let str):
            return str
        }
    }
    
    var intValue: Int {
        switch self {
        case .mainnet:
            return 1
        case .ropsten:
            return 3
        case .rinkeby:
            return 4
        case .goerli:
            return 5
        case .kovan:
            return 42
        case .sepolia:
            return 11155111
        case .custom(let str):
            return Int(str) ?? 0
        }
    }
}

public func ==(lhs: EthereumNetwork, rhs: EthereumNetwork) -> Bool {
    return lhs.stringValue == rhs.stringValue
}
