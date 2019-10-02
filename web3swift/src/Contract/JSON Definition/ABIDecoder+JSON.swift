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
        let rawTypes = types.compactMap { ABIRawType(rawValue: $0) }
        guard rawTypes.count == types.count else {
            throw ABIError.incorrectParameterCount
        }
        
        let rawDecoded = try ABIDecoder.decodeData(data, types: rawTypes)
        let decoded: [Any] = zip(rawDecoded, rawTypes).map { raw, type in
            if type.isArray {
                return raw
            } else {
                return raw.first ?? ""
            }
        }
        return decoded
    }
    
    public static func decode(_ data: String, type: String) throws -> Any {
        guard let bytes = data.web3.bytesFromHex else { throw ABIError.invalidValue }
        guard let type = ABIRawType(rawValue: type) else { throw ABIError.invalidType }
        
        return try decode(bytes, forType: type, offset: 0)
    }
    
}
