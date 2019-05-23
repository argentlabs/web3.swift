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
    static func decodeData(_ data: String, types: [ABIType.Type]) throws -> [ABIType] {
        let rawTypes = types.map { ABIRawType(type: $0) }.compactMap { $0 }
        return try ABIDecoder.decodeData(data, types: rawTypes)
    }
    
    public static func decode(_ data: String, to: String.Type) throws -> String {
        return data.stringValue
    }
    
    public static func decode(_ data: String, to: Bool.Type) throws -> Bool {
        return data == "0x01" ? true : false
    }
    
    public static func decode(_ data: String, to: EthereumAddress.Type) throws -> EthereumAddress {
        // If from log value, already decoded during initial log decode process
        if data.count == EthereumAddress.zero.value.count {
            return EthereumAddress(data)
        }
        
        guard let bytes = data.bytesFromHex else { throw ABIError.invalidValue }
        
        guard let decodedData = try ABIDecoder.decode(bytes, forType: ABIRawType.FixedAddress, offset: 0) as? String else {
            throw ABIError.invalidValue
        }
        
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
    
    public static func decode(_ data: String, to: UInt8.Type) throws -> UInt8 {
        guard let value = BigUInt(hex: data) else { throw ABIError.invalidValue }
        guard value.bitWidth <= 8 else { throw ABIError.invalidValue }
        return UInt8(value)
    }
    
    public static func decode(_ data: String, to: UInt16.Type) throws -> UInt16 {
        guard let value = BigUInt(hex: data) else { throw ABIError.invalidValue }
        guard value.bitWidth <= 16 else { throw ABIError.invalidValue }
        return UInt16(value)
    }
    
    public static func decode(_ data: String, to: UInt32.Type) throws -> UInt32 {
        guard let value = BigUInt(hex: data) else { throw ABIError.invalidValue }
        guard value.bitWidth <= 32 else { throw ABIError.invalidValue }
        return UInt32(value)
    }
    
    public static func decode(_ data: String, to: UInt64.Type) throws -> UInt64 {
        guard let value = BigUInt(hex: data) else { throw ABIError.invalidValue }
        guard value.bitWidth <= 64 else { throw ABIError.invalidValue }
        return UInt64(value)
    }
    
    public static func decode(_ data: String, to: URL.Type) throws -> URL {
        // If from log value, already decoded during initial log decode process
        let filtered = data.stringValue.trimmingCharacters(in: CharacterSet(charactersIn: "\0"))
        guard let url = URL(string: filtered) else {
            throw ABIError.invalidValue
        }
        
        return url
    }

    public static func decode(_ data: String, to: Data.Type) throws -> Data {
        guard let data = Data(hex: data) else { throw ABIError.invalidValue }
        return data
    }

}
