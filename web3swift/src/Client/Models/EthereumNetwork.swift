//
//  EthereumNetwork.swift
//  web3swift
//
//  Created by Matt Marshall on 09/03/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation

public enum EthereumNetwork: Equatable, Decodable {
    case Mainnet
    case Ropsten
    case Rinkeby
    case Kovan
    case Custom(String)

    static func fromString(_ networkId: String) -> EthereumNetwork {
        switch networkId {
        case "1":
            return .Mainnet
        case "3":
            return .Ropsten
        case "4":
            return .Rinkeby
        case "42":
            return .Kovan
        default:
            return .Custom(networkId)
        }
    }

    var stringValue: String {
        switch self {
        case .Mainnet:
            return "1"
        case .Ropsten:
            return "3"
        case .Rinkeby:
            return "4"
        case .Kovan:
            return "42"
        case .Custom(let str):
            return str
        }
    }

    var intValue: Int {
        switch self {
        case .Mainnet:
            return 1
        case .Ropsten:
            return 3
        case .Rinkeby:
            return 4
        case .Kovan:
            return 42
        case .Custom(let str):
            return Int(str) ?? 0
        }
    }
}

public func ==(lhs: EthereumNetwork, rhs: EthereumNetwork) -> Bool {
    return lhs.stringValue == rhs.stringValue

}
