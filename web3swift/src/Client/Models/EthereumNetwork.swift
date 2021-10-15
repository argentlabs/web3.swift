//
//  EthereumNetwork.swift
//  web3swift
//
//  Created by Matt Marshall on 09/03/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation

public enum EthereumNetwork: Equatable {
    case mainnet
    case ropsten
    case rinkeby
    case kovan
    case xDai
    case sokol
    case Custom(String)
    
    static func fromString(_ networkId: String) -> EthereumNetwork {
        switch networkId {
        case "1":
            return .mainnet
        case "3":
            return .ropsten
        case "4":
            return .rinkeby
        case "42":
            return .kovan
        case "100":
            return .xDai
        case "99":
            return .sokol
        default:
            return .Custom(networkId)
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
        case .kovan:
            return "42"
        case .xDai:
            return "100"
        case .sokol:
            return "99"
        case .Custom(let str):
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
        case .kovan:
            return 42
        case .xDai:
            return 100
        case .sokol:
            return 99
        case .Custom(let str):
            return Int(str) ?? 0
        }
    }
}

public func ==(lhs: EthereumNetwork, rhs: EthereumNetwork) -> Bool {
    return lhs.stringValue == rhs.stringValue
    
}
