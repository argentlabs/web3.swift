//
//  ABIEncoder+Static.swift
//  web3swift
//
//  Created by Matt Marshall on 10/04/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation
import BigInt

extension ABIEncoder {
    public static func encode(_ value: ABIType,
                              staticSize: ABIFixedSizeDataType.Type? = nil) throws -> EncodedValue {
        guard let type = ABIRawType(type: type(of: value)) else {
            throw ABIError.invalidType
        }
        switch value {
        case let value as String:
            return try ABIEncoder.encode(value, forType: type)
        case let value as Bool:
            return try ABIEncoder.encode(value ? "true" : "false", forType: type)
        case let value as EthereumAddress:
            return try ABIEncoder.encode(value.value, forType: type)
        case let value as BigInt:
            return try ABIEncoder.encode(String(value), forType: type)
        case let value as BigUInt:
            return try ABIEncoder.encode(String(value), forType: type)
        case let data as Data:
            if let staticSize = staticSize.flatMap(ABIRawType.init(type:)) {
                return try ABIEncoder.encode(String(bytes: data.web3.bytes), forType: staticSize, size: staticSize.size)
            } else {
                return try ABIEncoder.encode(String(bytes: data.web3.bytes), forType: type)
            }
        case let values as [ABIType]:
            let encoded = try values.map { try ABIEncoder.encode($0, staticSize: staticSize) }
            let raw = encoded.flatMap(\.encoded)
            return try ABIEncoder.encode(String(hexFromBytes: raw), forType: type, size: values.count)
        default:
            fatalError("Type not supported")
        }
    }

    static func signature(name: String, types: [ABIType.Type]) throws -> [UInt8] {
        let rawTypes = types.map { ABIRawType(type: $0) }.compactMap { $0 }
        return try signature(name: name, types: rawTypes)
    }
}
