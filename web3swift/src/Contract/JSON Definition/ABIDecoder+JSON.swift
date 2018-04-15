//
//  ABIDecoder+JSON.swift
//  web3swift
//
//  Created by Matt Marshall on 10/04/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation

extension ABIDecoder {
    public static func decodeData(_ data: String, types: [String]) throws -> [Any] {
        let rawTypes = types.map { ABIRawType(rawValue: $0) }.flatMap { $0 }
        return try ABIDecoder.decodeData(data, types: rawTypes)
    }
    
    public static func decode(_ data: String, type: String) throws -> Any {
        guard let bytes = data.bytesFromHex else { throw ABIError.invalidValue }
        guard let type = ABIRawType(rawValue: type) else { throw ABIError.invalidType }
        
        return try decode(bytes, forType: type, offset: 0)
    }
    
}
