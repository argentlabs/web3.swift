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
    public func decode(_ data: Data, expectedTypes: [ABIType.Type]) throws -> [ABIType] {
        let encoder = ABIFunctionEncoder(Self.name)
        try encode(to: encoder)
        let rawTypes = encoder.types
        let methodId = String(hexFromBytes: try ABIEncoder.methodId(name: Self.name, types: rawTypes))
        var raw = data.web3.hexString
        
        guard raw.hasPrefix(methodId) else {
            throw ABIError.invalidSignature
        }
        raw = raw.replacingOccurrences(of: methodId, with: "")
        return try ABIDecoder.decodeData(raw, types: expectedTypes)
    }
}

public class ABIFunctionEncoder {
    private let name: String
    private (set) var types: [ABIRawType] = []
    
    public func encode(_ value: String) throws {
        let strValue = value
        guard let type = ABIRawType(type: String.self) else { throw ABIError.invalidType }
        return try self.encode(type: type, value: strValue)
    }
    
    public func encode(_ value: Bool) throws {
        let strValue = value ? "true" : "false"
        guard let type = ABIRawType(type: Bool.self) else { throw ABIError.invalidType }
        return try self.encode(type: type, value: strValue)
    }
    
    public func encode(_ value: EthereumAddress) throws {
        let strValue = value.value
        guard let type = ABIRawType(type: EthereumAddress.self) else { throw ABIError.invalidType }
        return try self.encode(type: type, value: strValue)
    }
    
    public func encode(_ value: BigInt) throws {
        let strValue = String(value)
        guard let type = ABIRawType(type: BigInt.self) else { throw ABIError.invalidType }
        return try self.encode(type: type, value: strValue)
    }
    
    public func encode(_ value: BigUInt) throws {
        let strValue = String(value)
        guard let type = ABIRawType(type: BigUInt.self) else { throw ABIError.invalidType }
        return try self.encode(type: type, value: strValue)
    }
    
    public func encode(_ value: Data) throws {
        let strValue = String(bytes: value.web3.bytes)
        guard let type = ABIRawType(type: Data.self) else { throw ABIError.invalidType }
        return try self.encode(type: type, value: strValue)
    }
    
    public func encode(_ value: Data, size: ABIFixedSizeDataType.Type) throws {
        let strValue = String(bytes: value.web3.bytes)
        guard let type = ABIRawType(type: size) else { throw ABIError.invalidType }
        return try self.encode(type: type, value: strValue)
    }
    
    public func encode(_ value: [Data], size: ABIFixedSizeDataType.Type) throws {
        let strValue = String(bytes: value.flatMap { $0 })
        guard let containedType = ABIRawType(type: size) else { throw ABIError.invalidType }
        let type: ABIRawType = .DynamicArray(containedType)
        return try self.encode(type: type, value: strValue)
    }
    
    public func encode(_ value: [EthereumAddress]) throws {
        guard let type = ABIRawType(type: [EthereumAddress].self) else {
            throw ABIError.invalidType
        }
        let bytes = try value.flatMap { try ABIEncoder.encode($0) }
        return try self.encode(type: type, value: String(hexFromBytes: bytes), size: value.count)
    }

    private struct EncodedValue {
        let encoded: [UInt8]
        let isDynamic: Bool
        let staticLength: Int
    }
    private var encodedValues = [EncodedValue]()
    private func encode(type: ABIRawType, value: String, size: Int = 1) throws {
        let result = try ABIEncoder.encode(value, forType: type, size: size)
        
        let staticLength: Int
        if type.isDynamic {
            staticLength = 32
        } else {
            staticLength = 32 * size
        }
        
        encodedValues.append(EncodedValue(encoded: result, isDynamic: type.isDynamic, staticLength: staticLength))
        types.append(type)
    }
    
    public init(_ name: String) {
        self.name = name
    }
    
    private func calculateData() -> [UInt8] {
        var head = [UInt8]()
        var tail = [UInt8]()
        
        let offset = encodedValues.map { $0.staticLength }.reduce(0, +)
        
        encodedValues.forEach {
            if $0.isDynamic {
                let position = offset + (tail.count)
                head += try! ABIEncoder.encode(String(position), forType: ABIRawType.FixedInt(256))
                tail += $0.encoded
            } else {
                head += $0.encoded
            }
        }
        
        return head + tail
    }
    
    func encoded() throws -> Data {
        let methodId = try ABIEncoder.methodId(name: name, types: types)
        let allBytes = methodId + calculateData()
        return Data(allBytes)
    }
    
}
