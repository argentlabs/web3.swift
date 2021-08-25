//
//  ABIFunctionEncoder.swift
//  web3swift
//
//  Created by Matt Marshall on 09/04/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation
import BigInt

extension ABIFunction {
    public func decode(_ data: Data, expectedTypes: [ABIType.Type]) throws -> [ABIDecoder.DecodedValue] {
        let encoder = ABIFunctionEncoder(Self.name)
        try encode(to: encoder)
        let rawTypes = encoder.types
        let methodId = String(hexFromBytes: try ABIFunctionEncoder.methodId(name: Self.name, types: rawTypes))
        var raw = data.web3.hexString
        
        guard raw.hasPrefix(methodId) else {
            throw Web3Error.invalidSignature
        }
        raw = raw.replacingOccurrences(of: methodId, with: "")
        let decoded = try ABIDecoder.decodeData(raw, types: expectedTypes)
        let empty = decoded.flatMap { $0.entry.filter(\.isEmpty) }
        guard
            empty.count == 0,
            decoded.count == expectedTypes.count else {
            throw Web3Error.invalidSignature
        }
        
        return decoded
    }
}

public class ABIFunctionEncoder {
    private let name: String
    private (set) var types: [ABIRawType] = []
    
    public func encode(_ value: ABIType, staticSize: Int? = nil) throws {
        let rawType = type(of: value).rawType
        let encoded = try ABIEncoder.encode(value, staticSize: staticSize)
        
        encodedValues.append(encoded)
        switch (staticSize, rawType) {
        case (let size?, .DynamicBytes):
            guard size <= 32 else {
                throw Web3Error.invalidType
            }
            types.append(.FixedBytes(size))
        case (let size?, .FixedUInt):
            guard size <= 256 else {
                throw Web3Error.invalidType
            }
            types.append(.FixedUInt(size))
        case (let size?, .FixedInt):
            guard size <= 256 else {
                throw Web3Error.invalidType
            }
            types.append(.FixedInt(size))
        default:
            types.append(rawType)
        }
    }
    
    public func encode<T: ABIType>(_ values: [T], staticSize: Int? = nil) throws {
        let encoded = try ABIEncoder.encode(values, staticSize: staticSize)
        encodedValues.append(encoded)
        types.append(.DynamicArray(T.rawType))
    }
    
    internal var encodedValues = [ABIEncoder.EncodedValue]()

    public init(_ name: String) {
        self.name = name
    }
    
    public func encoded() throws -> Data {
        let methodId = try Self.methodId(name: name, types: types)
        let allBytes = methodId + (try encodedValues.encoded(isDynamic: false))
        return Data(allBytes)
    }
    
    static func signature(name: String, types: [ABIRawType]) throws -> [UInt8] {
        let typeNames = types.map { $0.rawValue }
        let signature = name + "(" + typeNames.joined(separator: ",") + ")"
        guard let data = signature.data(using: .utf8) else { throw Web3Error.invalidSignature }
        return data.web3.keccak256.web3.bytes
    }
    
    static func signature(name: String, types: [ABIType.Type]) throws -> [UInt8] {
        let rawTypes = types.map { $0.rawType }
        return try signature(name: name, types: rawTypes)
    }
    
    static func methodId(name: String, types: [ABIRawType]) throws -> [UInt8] {
        let signature = try Self.signature(name: name, types: types)
        return Array(signature.prefix(4))
    }

}
