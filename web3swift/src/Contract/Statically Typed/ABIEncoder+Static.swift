//
//  ABIEncoder+Static.swift
//  web3swift
//
//  Created by Matt Marshall on 10/04/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation

extension ABIEncoder {
    static func signature(name: String, types: [ABIType.Type]) throws -> [UInt8] {
        let rawTypes = types.map { ABIRawType(type: $0) }.flatMap { $0 }
        return try signature(name: name, types: rawTypes)
    }
}
