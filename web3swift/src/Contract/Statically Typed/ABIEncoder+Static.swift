//
//  ABIEncoder+Static.swift
//  web3swift
//
//  Created by Matt Marshall on 10/04/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation

extension ABIEncoder {
    public static func encode(_ value: EthereumAddress) throws -> [UInt8] {
        guard let addressType = ABIRawType(type: EthereumAddress.self) else {
            throw ABIError.invalidType
        }
        
        return try ABIEncoder.encode(value.value, forType: addressType)
    }
    
    static func signature(name: String, types: [ABIType.Type]) throws -> [UInt8] {
        let rawTypes = types.map { ABIRawType(type: $0) }.compactMap { $0 }
        return try signature(name: name, types: rawTypes)
    }
}
