//
//  ABIEncoder+JSON.swift
//  web3swift
//
//  Created by Matt Marshall on 10/04/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation

extension ABIEncoder {
    public static func encode(function: String, args: [String], types: [String]) throws -> [UInt8] {
        
        let sig = try signature(name: function, types: types)
        let methodId = Array(sig.prefix(4))
        
        var head = [UInt8]()
        var tail = [UInt8]()
        for (index, value) in args.enumerated() {
            guard let type = ABIRawType(rawValue: types[index]) else {
                throw ABIError.invalidType
            }
            
            let result = try encode(value, forType: type)
            if type.isDynamic {
                let pos = args.count*32 + tail.count
                head += try encode(String(pos), forType: ABIRawType.FixedInt(256))
                tail += result
            }
            else {
                head += result
            }
        }
        return methodId + head + tail
    }
    
    public static func signature(name: String, types: [String]) throws -> [UInt8] {
        let rawTypes = types.map { ABIRawType(rawValue: $0) }.flatMap { $0 }
        return try signature(name: name, types: rawTypes)
    }
}
