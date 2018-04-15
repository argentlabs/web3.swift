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
