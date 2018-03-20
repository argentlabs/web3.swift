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
    public static func decode(data: String, types: [String]) throws -> [Any] {
        
        var result: [Any] = []
        var offset = 0
        
        for rawType in types {
            let type = ABIParser.normalizeType(type: rawType)
            let parsed = try ABIParser.parseType(type: type)
            if data == "0x" {
                parsed.isArray ? result.append([]) : result.append("")
            } else {
                guard let bytes = data.bytesFromHex else { throw EthereumContractError.invalidArgumentValue }
                let decoded = try decodeArgument(parsedType: parsed, data: bytes, offset: offset)
                result.append(decoded)
            }
            offset += parsed.memory
        }
        return result
    }
    
    static func decodeArgument(parsedType: ABIParsedType, data: [UInt8], offset: Int) throws -> Any {
        
        if parsedType.name == "address" {
            return try decodeArgument(parsedType: ABIParser.parseType(type: "uint160"), data: data, offset: offset)
        }
        if parsedType.name == "bool" {
            return try decodeArgument(parsedType: ABIParser.parseType(type: "uint8"), data: data, offset: offset)
        }
        if parsedType.name == "string" {
            return try decodeArgument(parsedType: ABIParser.parseType(type: "bytes"), data: data, offset: offset)
        }
        if parsedType.isArray {
            var result: [String] = []
            var size = parsedType.size
            var newOffset = offset
            if parsedType.isDynamic {
                guard let offsetHex = try decodeArgument(parsedType: ABIParser.parseType(type: "uint256"), data: data, offset: newOffset) as? String else {
                    throw EthereumContractError.invalidArgumentValue
                }
                newOffset = Int(hex: offsetHex) ?? newOffset
                guard let sizeHex = try decodeArgument(parsedType: ABIParser.parseType(type: "uint256"), data: data, offset: newOffset) as? String else {
                    throw EthereumContractError.invalidArgumentValue
                }
                size = Int(hex: sizeHex) ?? size
                newOffset += 32
            }
            while size > 0 {
                guard let arrayType = parsedType.arrayType, let stringValue = (try? decodeArgument(parsedType: ABIParser.parseType(type: arrayType), data: data, offset: newOffset)) as? String else {
                    throw EthereumContractError.invalidArgumentValue
                }
                result.append(stringValue)
                newOffset += parsedType.memory
                size -= 1
            }
            return result
        }
        if parsedType.name == "bytes" {
            guard let offsetHex = (try? decodeArgument(parsedType: ABIParser.parseType(type: "uint256"), data: data, offset: offset)) as? String, let newOffset = Int(hex: offsetHex) else {
                throw EthereumContractError.invalidArgumentValue
            }
            guard let sizeHex = (try? decodeArgument(parsedType: ABIParser.parseType(type: "uint256"), data: data, offset: newOffset)) as? String, let bint = BigInt(hex: sizeHex.noHexPrefix) else {
                throw EthereumContractError.invalidArgumentValue
            }
            let size = Int(bint)
            let hex = String(hexFromBytes: Array(data[newOffset + 32 ... newOffset + 32 + size - 1]))
            return hex
        }
        if parsedType.name.hasPrefix("uint") {
            let startIndex = offset + 32 - parsedType.size
            let endIndex = offset+31
            let hex = String(hexFromBytes: Array(data[startIndex...endIndex])) // we do not use BInt because address is treated as uint160 and BInt is based on 64 bits (160/64 = 2.5)
            return hex
        }
        if parsedType.name.hasPrefix("int") {
            let startIndex = offset + 32 - parsedType.size
            let endIndex = offset+31
            let buf = Data(bytes: Array(data[startIndex...endIndex]))
            let bint = BigInt(twosComplement: buf)
            return String(hexFromBytes: bint.bytes)
        }
        if parsedType.name.hasPrefix("bytes") {
            let startIndex = offset + 32 - parsedType.size
            let endIndex = offset+31
            let hex = String(hexFromBytes: Array(data[startIndex...endIndex]))
            return hex
        }
        throw EthereumContractError.notImplemented
    }
}
