//
//  ABIEntry.swift
//  web3swift
//
//  Created by Matt Marshall on 16/03/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation

public struct ABIEntry: Decodable {
    let name: String?
    let type: String
    let inputs: [ABIParameter]?
    let outputs: [ABIParameter]?    // Functions only
    let payable: Bool?              // Functions only
    let stateMutability: String?    // Functions only
    let constant: Bool?             // Functions only
    let anonymous: Bool?            // Events only
}

public struct ABIParameter: Decodable {
    let name: String
    let type: String
    let indexed: Bool? // Events only
}
