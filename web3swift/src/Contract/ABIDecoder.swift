//
//  ABIDecoder.swift
//  web3swift
//
//  Created by Matt Marshall on 16/03/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation
import BigInt

public class ABIDecoder {
    static func decodeData(_ data: String, types: [ABIRawType]) throws -> [ABIType] {
        var result: [ABIType] = []
        var offset = 0
        for type in types {
            if data == "0x" {
                type.isArray ? result.append([]) : result.append("")
            } else {
                guard let bytes = data.bytesFromHex else { throw ABIError.invalidValue }
                let decoded = try decode(bytes, forType: type, offset: offset)
                result.append(decoded)
            }
            offset += type.memory
        }
        return result
    }
    
    static func decode(_ data: [UInt8], forType type: ABIRawType, offset: Int) throws -> ABIType {
        switch type {
        case .FixedBool:
            return try decode(data, forType: ABIRawType.FixedUInt(8), offset: offset)
        case .FixedAddress:
            return try decode(data, forType: ABIRawType.FixedUInt(160), offset: offset)
        case .DynamicString:
            return try decode(data, forType: ABIRawType.DynamicBytes, offset: offset)
        case .DynamicBytes:
            guard let offsetHex = (try? decode(data, forType: ABIRawType.FixedUInt(256), offset: offset)) as? String, let newOffset = Int(hex: offsetHex) else {
                throw ABIError.invalidValue
            }
            guard let sizeHex = (try? decode(data, forType: ABIRawType.FixedUInt(256), offset: newOffset)) as? String, let bint = BigInt(hex: sizeHex.noHexPrefix) else {
                throw ABIError.invalidValue
            }
            let size = Int(bint)
            guard size > 0 else {
                return ""
            }
            let lowerRange = newOffset + 32
            let upperRange = newOffset + 32 + size - 1
            guard lowerRange <= upperRange else { throw ABIError.invalidValue }
            guard data.count > upperRange else { throw ABIError.invalidValue }
            let hex = String(hexFromBytes: Array(data[lowerRange...upperRange]))
            return hex
        case .FixedInt(_):
            let startIndex = offset + 32 - type.size
            let endIndex = offset + 31
            guard data.count > endIndex else { throw ABIError.invalidValue }
            let buf = Data(bytes: Array(data[startIndex...endIndex]))
            let bint = BigInt(twosComplement: buf)
            return String(hexFromBytes: bint.bytes)
        case .FixedUInt(_):
            let startIndex = offset + 32 - type.size
            let endIndex = offset + 31
            guard data.count > endIndex else { throw ABIError.invalidValue }
            let hex = String(hexFromBytes: Array(data[startIndex...endIndex])) // Do not use BInt because address is treated as uint160 and BInt is based on 64 bits (160/64 = 2.5)
            return hex
        case .FixedBytes(_):
            let startIndex = offset + 32 - type.size
            let endIndex = offset + 31
            guard data.count > endIndex else { throw ABIError.invalidValue }
            let hex = String(hexFromBytes: Array(data[startIndex...endIndex]))
            return hex
        case .FixedArray(let arrayType, _):
            var result: [String] = []
            var size = type.size
            var newOffset = offset
            
            try deepDecode(data: data, type: arrayType, result: &result, offset: &newOffset, size: &size)
            return result
        case .DynamicArray(let arrayType):
            var result: [String] = []
            var newOffset = offset
            
            guard let offsetHex = (try? decode(data, forType: ABIRawType.FixedUInt(256), offset: newOffset)) as? String else {
                throw ABIError.invalidValue
            }
            newOffset = Int(hex: offsetHex) ?? newOffset
            
            guard let sizeHex = (try? decode(data, forType: ABIRawType.FixedUInt(256), offset: newOffset)) as? String else {
                throw ABIError.invalidValue
            }
            guard var size = Int(hex: sizeHex) else {
                throw ABIError.invalidValue
            }
            newOffset += 32
            
            try deepDecode(data: data, type: arrayType, result: &result, offset: &newOffset, size: &size)
            return result
        }
    }
    
    private static func deepDecode(data: [UInt8], type: ABIRawType, result: inout [String], offset: inout Int, size: inout Int) throws -> Void {
        if size < 1 { return }
        
        guard let stringValue = (try? decode(data, forType: type, offset: offset)) as? String else {
            throw ABIError.invalidValue
        }
        result.append(stringValue)
        offset += type.memory
        size -= 1
        
        try deepDecode(data: data, type: type, result: &result, offset: &offset, size: &size)
    }
}
