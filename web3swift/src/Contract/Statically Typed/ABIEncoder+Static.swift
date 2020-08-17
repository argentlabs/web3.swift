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
                              staticSize: Int? = nil) throws -> EncodedValue {
        let type = Swift.type(of: value).rawType
        switch value {
        case let value as String:
            return try ABIEncoder.encodeRaw(value, forType: type)
        case let value as Bool:
            return try ABIEncoder.encodeRaw(value ? "true" : "false", forType: type)
        case let value as EthereumAddress:
            return try ABIEncoder.encodeRaw(value.value, forType: type)
        case let value as BigInt:
            return try ABIEncoder.encodeRaw(String(value), forType: type)
        case let value as BigUInt:
            return try ABIEncoder.encodeRaw(String(value), forType: type)
        case let value as UInt8:
            return try ABIEncoder.encodeRaw(String(value), forType: type)
        case let value as UInt16:
            return try ABIEncoder.encodeRaw(String(value), forType: type)
        case let value as UInt32:
            return try ABIEncoder.encodeRaw(String(value), forType: type)
        case let value as UInt64:
            return try ABIEncoder.encodeRaw(String(value), forType: type)
        case let data as Data:
            if let staticSize = staticSize {
                return try ABIEncoder.encodeRaw(String(bytes: data.web3.bytes), forType: .FixedBytes(staticSize))
            } else {
                return try ABIEncoder.encodeRaw(String(bytes: data.web3.bytes), forType: type)
            }
        
        case let value as ABITuple:
            let sizeToEncode = type.isDynamic && value.encodableValues.count > 1 ? value.encodableValues.count : nil
            return try ABIEncoder.encodeArray(elements: value.encodableValues.map { (value: $0, size: nil)}, isDynamic: type.isDynamic, size: sizeToEncode)
        default:
            throw ABIError.notCurrentlySupported
        }
    }
    
    public static func encode<T: ABIType>(_ values: [T],
                              staticSize: Int? = nil) throws -> EncodedValue {
        return try ABIEncoder.encodeArray(elements: values.map { (value: $0, size: nil) }, isDynamic: staticSize == nil, size: values.count)
    }
    
    private typealias ValueAndSize = (value: ABIType, size: Int?)
    private static func encodeArray(elements: [ValueAndSize], isDynamic: Bool, size: Int?) throws -> EncodedValue {
        let values: [EncodedValue] = try elements.map {
            try ABIEncoder.encode($0.value, staticSize: $0.size)
        }

        return .container(values: values, isDynamic: isDynamic, size: size)
    }
}
