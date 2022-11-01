//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import BigInt
import Foundation

extension ABIEncoder {
    public static func encode(_ value: ABIType,
                              staticSize: Int? = nil,
                              packed: Bool = false) throws -> EncodedValue {
        let type = Swift.type(of: value).rawType
        switch value {
        case let value as String:
            return try ABIEncoder.encodeRaw(value, forType: type, padded: !packed)
        case let value as Bool:
            return try ABIEncoder.encodeRaw(value ? "true" : "false", forType: type, padded: !packed)
        case let value as EthereumAddress:
            return try ABIEncoder.encodeRaw(value.value, forType: type, padded: !packed)
        case let value as BigInt:
            return try ABIEncoder.encodeRaw(String(value), forType: type, padded: !packed)
        case let value as BigUInt:
            return try ABIEncoder.encodeRaw(String(value), forType: type, padded: !packed)
        case let value as UInt8:
            return try ABIEncoder.encodeRaw(String(value), forType: type, padded: !packed)
        case let value as UInt16:
            return try ABIEncoder.encodeRaw(String(value), forType: type, padded: !packed)
        case let value as UInt32:
            return try ABIEncoder.encodeRaw(String(value), forType: type, padded: !packed)
        case let value as UInt64:
            return try ABIEncoder.encodeRaw(String(value), forType: type, padded: !packed)
        case let data as Data:
            if let staticSize = staticSize {
                return try ABIEncoder.encodeRaw(String(bytes: data.web3.bytes), forType: .FixedBytes(staticSize), padded: !packed)
            } else {
                return try ABIEncoder.encodeRaw(String(bytes: data.web3.bytes), forType: type, padded: !packed)
            }

        case let value as ABITuple:
            return try encodeTuple(value, type: type)
        default:
            throw ABIError.notCurrentlySupported
        }
    }

    public static func encode<T: ABIType>(_ values: [T],
                                          staticSize: Int? = nil,
                                          elementRawType: ABIRawType? = nil) throws -> EncodedValue {
        return try ABIEncoder.encodeArray(elements: values.map { (value: $0, size: elementRawType != nil ? elementRawType!.size : nil) },
                                          isDynamic: staticSize == nil,
                                          size: values.count)
    }

    private typealias ValueAndSize = (value: ABIType, size: Int?)
    private static func encodeArray(elements: [ValueAndSize], isDynamic: Bool, size: Int?) throws -> EncodedValue {
        let values: [EncodedValue] = try elements.map {
            try ABIEncoder.encode($0.value, staticSize: $0.size)
        }

        return .container(values: values, isDynamic: isDynamic, size: size)
    }

    private static func encodeTuple(_ tuple: ABITuple, type: ABIRawType) throws -> EncodedValue {
        let encoder = ABIFunctionEncoder("")
        try tuple.encode(to: encoder)

        return .container(values: encoder.encodedValues, isDynamic: type.isDynamic, size: nil)
    }
}
