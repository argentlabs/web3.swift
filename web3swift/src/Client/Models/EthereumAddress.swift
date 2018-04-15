//
//  EthereumAddress.swift
//  web3swift
//
//  Created by Matt Marshall on 06/04/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation

public struct EthereumAddress: Codable {
    public let value: String
    
    public init(_ value: String) {
        self.value = value
    }
}
