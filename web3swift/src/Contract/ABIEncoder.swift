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
    /* Warning: does not handle all the types (including arrays) */
    public static func encode(function: String, args: [String], types: [String]) throws -> [UInt8] {
        
        let sig = try signature(name: function, types: types)
        let methodId = Array(sig.prefix(4))
        
        var head = [UInt8]()
        var tail = [UInt8]()
        for (index,value) in args.enumerated() {
            let type = types[index]
            let result = try encodeArgument(type: type, arg: value)
            if ABIParser.isDynamic(type: type) {
                let pos = args.count*32 + tail.count
                head += try encodeArgument(type: "int", arg: String(pos))
                tail += result
            }
            else {
                head += result
            }
        }
        return methodId + head + tail
    }
    
    static func encodeArgument(type: String, arg: String) throws -> [UInt8] {
        
        var encoded: [UInt8] = [UInt8]()
        
        if type.hasPrefix("uint") {
            guard arg.isNumeric, let value = BigInt(arg) else {
                throw EthereumContractError.invalidArgumentType
            }
            let bytes = value.bytes // should be <= 32 bytes
            guard bytes.count <= 32 else {
                throw EthereumContractError.invalidArgumentValue
            }
            encoded = [UInt8](repeating: 0x00, count: 32 - bytes.count) + bytes
        }
        else if type.hasPrefix("int") {
            guard Double(arg) != nil, let value = BigInt(arg) else {
                throw EthereumContractError.invalidArgumentType
            }
            
            let bytes = value.bytes // should be <= 32 bytes
            guard bytes.count <= 32 else {
                throw EthereumContractError.invalidArgumentValue
            }
            
            if value < 0 {
                encoded = [UInt8](repeating: 0xff, count: 32 - bytes.count) + bytes
            } else {
                encoded = [UInt8](repeating: 0, count: 32 - bytes.count) + bytes
            }
        }
        else if type == "bool" {
            encoded = try encodeArgument(type: "uint8", arg: arg == "true" ? "1":"0")
        }
        else if type == "address" {
            guard let bytes = arg.bytesFromHex else { throw EthereumContractError.invalidArgumentValue } // Must be 20 bytes
            encoded = [UInt8](repeating: 0x00, count: 32 - bytes.count) + bytes
        }
        else if type == "string" {
            let bytes = arg.bytes
            let len = try encodeArgument(type: "uint256", arg: String(bytes.count))
            let pack = (bytes.count - (bytes.count % 32)) / 32 + 1
            encoded = len + bytes + [UInt8](repeating: 0x00, count: pack * 32 - bytes.count)
        }
        else if type == "bytes" {
            // Bytes are hex encoded
            guard let bytes = arg.bytesFromHex else { throw EthereumContractError.invalidArgumentValue }
            let len = try encodeArgument(type: "uint256", arg: String(bytes.count))
            let pack = (bytes.count - (bytes.count % 32)) / 32 + 1
            encoded = len + bytes + [UInt8](repeating: 0x00, count: pack * 32 - bytes.count)
        }
        else if type.hasPrefix("bytes") {
            // Bytes are hex encoded
            guard let bytes = arg.bytesFromHex else { throw EthereumContractError.invalidArgumentValue }
            encoded = [UInt8](repeating: 0x00, count: 32 - bytes.count) + bytes
        }
        else {
            throw EthereumContractError.notImplemented
        }
        
        return encoded
    }
    
    static func signature(name: String, types: [String]) throws -> [UInt8] {
        let signature = name + "(" + types.map { ABIParser.normalizeType(type: $0) }.joined(separator: ",") + ")"
        guard let data = signature.data(using: .utf8) else { throw EthereumContractError.invalidSignature }
        return data.keccak256.bytes
    }
}
