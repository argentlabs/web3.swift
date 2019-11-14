//
//  ABIEncoder.swift
//  web3swift
//
//  Created by Matt Marshall on 16/03/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation
import BigInt

public class ABIEncoder {
    
    static func encode(_ value: String,
                       forType type: ABIRawType,
                       packed: Bool = true,
                       size: Int = 1) throws -> [UInt8] {
        var encoded: [UInt8] = [UInt8]()
        
        switch type {
        case .FixedUInt(_):
            guard value.web3.isNumeric, let int = BigInt(value) else {
                throw ABIError.invalidType
            }
            let bytes = int.web3.bytes // should be <= 32 bytes
            guard bytes.count <= 32 else {
                throw ABIError.invalidValue
            }
            if packed {
                encoded = [UInt8](repeating: 0x00, count: 32 - bytes.count) + bytes
            } else {
                encoded = bytes
            }
        case .FixedInt(_):
            guard Double(value) != nil, let int = BigInt(value) else {
                throw ABIError.invalidType
            }
            
            let bytes = int.web3.bytes // should be <= 32 bytes
            guard bytes.count <= 32 else {
                throw ABIError.invalidValue
            }
            
            if int < 0 {
                encoded = [UInt8](repeating: 0xff, count: 32 - bytes.count) + bytes
            } else {
                encoded = [UInt8](repeating: 0, count: 32 - bytes.count) + bytes
            }
            
            if !packed {
                encoded = bytes
            }
        case .FixedBool:
            encoded = try encode(value == "true" ? "1":"0", forType: ABIRawType.FixedUInt(8))
        case .FixedAddress:
            guard let bytes = value.web3.bytesFromHex else { throw ABIError.invalidValue } // Must be 20 bytes
            if packed  {
                encoded = [UInt8](repeating: 0x00, count: 32 - bytes.count) + bytes
            } else {
                encoded = bytes
            }
        case .DynamicString:
            let bytes = value.web3.bytes
            let len = try encode(String(bytes.count), forType: ABIRawType.FixedUInt(256))
            let pack = (bytes.count - (bytes.count % 32)) / 32 + 1
            encoded = len + bytes
            if packed {
                encoded += [UInt8](repeating: 0x00, count: pack * 32 - bytes.count)
            }
        case .DynamicBytes:
            // Bytes are hex encoded
            guard let bytes = value.web3.bytesFromHex else { throw ABIError.invalidValue }
            let len = try encode(String(bytes.count), forType: ABIRawType.FixedUInt(256))
            let pack: Int
            if bytes.count == 0 {
                pack = 0
            } else {
                pack = (bytes.count - (bytes.count % 32)) / 32 + 1
            }
            
            encoded = len + bytes
            if packed {
                encoded += [UInt8](repeating: 0x00, count: pack * 32 - bytes.count)
            }
        case .FixedBytes(_):
            // Bytes are hex encoded
            guard let bytes = value.web3.bytesFromHex else { throw ABIError.invalidValue }
            encoded = bytes
            if packed {
                encoded += [UInt8](repeating: 0x00, count: 32 - bytes.count)
            }
        case .DynamicArray(let type):
            let unitSize = type.size * 2
            let stringValue = value.web3.noHexPrefix
            let size = stringValue.count / unitSize

            var bytes = [UInt8]()
            for i in (0..<size) {
                let start =  stringValue.index(stringValue.startIndex, offsetBy: i * unitSize)
                let end = stringValue.index(start, offsetBy: unitSize)
                let unitValue = String(stringValue[start..<end])
                let unitBytes = try encode(unitValue, forType: type, packed: false)
                bytes.append(contentsOf: unitBytes)
            }
            let len = try encode(String(size), forType: ABIRawType.FixedUInt(256))
            
            let pack: Int
            if bytes.count == 0 {
                pack = 0
            } else {
                pack = (bytes.count - (bytes.count % 32)) / 32 + 1
            }
            
            encoded = len + bytes + [UInt8](repeating: 0x00, count: pack * 32 - bytes.count)
        case .FixedArray(_, _):
            throw ABIError.notCurrentlySupported // TODO
        }
    
        return encoded
    }
    
    static func signature(name: String, types: [ABIRawType]) throws -> [UInt8] {
        let typeNames = types.map { $0.rawValue }
        let signature = name + "(" + typeNames.joined(separator: ",") + ")"
        guard let data = signature.data(using: .utf8) else { throw ABIError.invalidSignature }
        return data.web3.keccak256.web3.bytes
    }
    
    static func methodId(name: String, types: [ABIRawType]) throws -> [UInt8] {
        let signature = try Self.signature(name: name, types: types)
        return Array(signature.prefix(4))
    }
}


