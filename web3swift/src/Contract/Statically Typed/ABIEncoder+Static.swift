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
        case let value as Data1:
            return try ABIEncoder.encodeRaw(String(bytes: value.rawData.web3.bytes), forType: Data1.rawType, padded: !packed)
        case let value as Data2:
            return try ABIEncoder.encodeRaw(String(bytes: value.rawData.web3.bytes), forType: Data2.rawType, padded: !packed)
        case let value as Data3:
            return try ABIEncoder.encodeRaw(String(bytes: value.rawData.web3.bytes), forType: Data3.rawType, padded: !packed)
        case let value as Data4:
            return try ABIEncoder.encodeRaw(String(bytes: value.rawData.web3.bytes), forType: Data4.rawType, padded: !packed)
        case let value as Data5:
            return try ABIEncoder.encodeRaw(String(bytes: value.rawData.web3.bytes), forType: Data5.rawType, padded: !packed)
        case let value as Data6:
            return try ABIEncoder.encodeRaw(String(bytes: value.rawData.web3.bytes), forType: Data6.rawType, padded: !packed)
        case let value as Data7:
            return try ABIEncoder.encodeRaw(String(bytes: value.rawData.web3.bytes), forType: Data7.rawType, padded: !packed)
        case let value as Data8:
            return try ABIEncoder.encodeRaw(String(bytes: value.rawData.web3.bytes), forType: Data8.rawType, padded: !packed)
        case let value as Data9:
            return try ABIEncoder.encodeRaw(String(bytes: value.rawData.web3.bytes), forType: Data9.rawType, padded: !packed)
        case let value as Data10:
            return try ABIEncoder.encodeRaw(String(bytes: value.rawData.web3.bytes), forType: Data10.rawType, padded: !packed)
        case let value as Data11:
            return try ABIEncoder.encodeRaw(String(bytes: value.rawData.web3.bytes), forType: Data11.rawType, padded: !packed)
        case let value as Data12:
            return try ABIEncoder.encodeRaw(String(bytes: value.rawData.web3.bytes), forType: Data12.rawType, padded: !packed)
        case let value as Data13:
            return try ABIEncoder.encodeRaw(String(bytes: value.rawData.web3.bytes), forType: Data13.rawType, padded: !packed)
        case let value as Data14:
            return try ABIEncoder.encodeRaw(String(bytes: value.rawData.web3.bytes), forType: Data14.rawType, padded: !packed)
        case let value as Data15:
            return try ABIEncoder.encodeRaw(String(bytes: value.rawData.web3.bytes), forType: Data15.rawType, padded: !packed)
        case let value as Data16:
            return try ABIEncoder.encodeRaw(String(bytes: value.rawData.web3.bytes), forType: Data16.rawType, padded: !packed)
        case let value as Data17:
            return try ABIEncoder.encodeRaw(String(bytes: value.rawData.web3.bytes), forType: Data17.rawType, padded: !packed)
        case let value as Data18:
            return try ABIEncoder.encodeRaw(String(bytes: value.rawData.web3.bytes), forType: Data18.rawType, padded: !packed)
        case let value as Data19:
            return try ABIEncoder.encodeRaw(String(bytes: value.rawData.web3.bytes), forType: Data19.rawType, padded: !packed)
        case let value as Data20:
            return try ABIEncoder.encodeRaw(String(bytes: value.rawData.web3.bytes), forType: Data20.rawType, padded: !packed)
        case let value as Data21:
            return try ABIEncoder.encodeRaw(String(bytes: value.rawData.web3.bytes), forType: Data21.rawType, padded: !packed)
        case let value as Data22:
            return try ABIEncoder.encodeRaw(String(bytes: value.rawData.web3.bytes), forType: Data22.rawType, padded: !packed)
        case let value as Data23:
            return try ABIEncoder.encodeRaw(String(bytes: value.rawData.web3.bytes), forType: Data23.rawType, padded: !packed)
        case let value as Data24:
            return try ABIEncoder.encodeRaw(String(bytes: value.rawData.web3.bytes), forType: Data24.rawType, padded: !packed)
        case let value as Data25:
            return try ABIEncoder.encodeRaw(String(bytes: value.rawData.web3.bytes), forType: Data25.rawType, padded: !packed)
        case let value as Data26:
            return try ABIEncoder.encodeRaw(String(bytes: value.rawData.web3.bytes), forType: Data26.rawType, padded: !packed)
        case let value as Data27:
            return try ABIEncoder.encodeRaw(String(bytes: value.rawData.web3.bytes), forType: Data27.rawType, padded: !packed)
        case let value as Data28:
            return try ABIEncoder.encodeRaw(String(bytes: value.rawData.web3.bytes), forType: Data28.rawType, padded: !packed)
        case let value as Data29:
            return try ABIEncoder.encodeRaw(String(bytes: value.rawData.web3.bytes), forType: Data29.rawType, padded: !packed)
        case let value as Data30:
            return try ABIEncoder.encodeRaw(String(bytes: value.rawData.web3.bytes), forType: Data30.rawType, padded: !packed)
        case let value as Data31:
            return try ABIEncoder.encodeRaw(String(bytes: value.rawData.web3.bytes), forType: Data31.rawType, padded: !packed)
        case let value as Data32:
            return try ABIEncoder.encodeRaw(String(bytes: value.rawData.web3.bytes), forType: Data32.rawType, padded: !packed)
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

    private static func encodeTuple(_ tuple: ABITuple, type: ABIRawType) throws -> EncodedValue {
        let encoder = ABIFunctionEncoder("")
        try tuple.encode(to: encoder)

        return .container(values: encoder.encodedValues, isDynamic: type.isDynamic, size: nil)
    }
}
