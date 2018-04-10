//
//  ABIDecoder+Static.swift
//  web3swift
//
//  Created by Matt Marshall on 10/04/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation
import BigInt

extension ABIDecoder {
    static func decodeData(_ data: String, types: [ABIType.Type]) throws -> [Any] {
        let rawTypes = types.map { ABIRawType(type: $0) }.flatMap { $0 }
        return try ABIDecoder.decodeData(data, types: rawTypes)
    }
    
    public static func decode(_ data: String, to: String.Type) throws -> String {
        return data
    }
    
    public static func decode(_ data: String, to: Bool.Type) throws -> Bool {
        return data == "0x01" ? true : false
    }
    
    public static func decode(_ data: String, to: EthereumAddress.Type) throws -> EthereumAddress {
        guard let bytes = data.bytesFromHex else { throw ABIError.invalidValue }
        guard let decodedData = try ABIDecoder.decode(bytes, forType: ABIRawType.FixedAddress, offset: 0) as? String else { throw ABIError.invalidValue }
        
        return EthereumAddress(decodedData)
    }
    
    public static func decode(_ data: String, to: BigInt.Type) throws -> BigInt {
        guard let value = BigInt(hex: data) else { throw ABIError.invalidValue }
        return value
    }
    
    public static func decode(_ data: String, to: BigUInt.Type) throws -> BigUInt {
        guard let value = BigUInt(hex: data) else { throw ABIError.invalidValue }
        return value
    }

    public static func decode(_ data: String, to: Data.Type) throws -> String {
        return data
    }
}
