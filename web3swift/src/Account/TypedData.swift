//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation
import BigInt
import GenericJSON

/// A type value description
public struct TypedVariable: Codable, Equatable {
    let name: String
    let type: String

    public init(name: String,
                type: String) {
        self.name = name
        self.type = type
    }
}

/// Typed data as per EIP712
public struct TypedData: Codable, Equatable {
    public let types: [String: [TypedVariable]]
    public let primaryType: String
    public let domain: JSON
    public let message: JSON

    public init(types: [String : [TypedVariable]],
                primaryType: String,
                domain: JSON,
                message: JSON) {
        self.types = types
        self.primaryType = primaryType
        self.domain = domain
        self.message = message
    }
}

extension TypedData: CustomStringConvertible {
    public var description: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        guard
            let encoded = try? encoder.encode(message),
            let string = String(data: encoded, encoding: .utf8) else {
                return ""
        }
        
        return string
    }
}

extension TypedData {
    public var typeHash: Data { encodeType(primaryType: primaryType).web3.keccak256 }

    // Whole data blob hash to sign
    public func signableHash() throws -> Data {
        var data = Data([0x19, 0x01])
        data.append(try encodeData(data: domain, type: "EIP712Domain").web3.keccak256)
        data.append(try encodeData(data: message, type: primaryType).web3.keccak256)
        return data.web3.keccak256
    }

    /// Type encoding as per EIP712
    public func encodeType(primaryType: String) -> Data {
        var depSet = findDependencies(primaryType: primaryType)
        depSet.remove(primaryType)
        let sorted = [primaryType] + Array(depSet).sorted()
        let encoded = sorted.map { type in
            let param = types[type]!.map { "\($0.type) \($0.name)" }.joined(separator: ",")
            return "\(type)(\(param))"
        }.joined()
        return encoded.data(using: .utf8) ?? Data()
    }

    /// Object encoding as per EIP712
    public func encodeData(data: JSON, type: String) throws -> Data {
        var encoded = try ABIEncoder.encode(encodeType(primaryType: type).web3.keccak256, staticSize: 32).bytes
        
        guard let valueTypes = types[type] else {
            throw ABIError.invalidType
        }
        
        let recursiveEncoded: [UInt8] = try valueTypes.flatMap { variable -> [UInt8] in
            if types[variable.type] != nil {
                guard let json = data[variable.name] else {
                    throw ABIError.invalidValue
                }
                return try encodeData(data: json, type: variable.type).web3.keccak256.web3.bytes
            } else if let json = data[variable.name] {
                return try parseAtomicType(json, type: variable.type)
            } else {
                return []
            }
        }
        
        encoded.append(contentsOf: recursiveEncoded)
        
        return Data(encoded)
    }
    
    private func findDependencies(primaryType: String, dependencies: Set<String> = Set<String>()) -> Set<String> {
        var found = dependencies
        guard !found.contains(primaryType),
            let primaryTypes = types[primaryType] else {
                return found
        }
        found.insert(primaryType)
        for type in primaryTypes {
            findDependencies(primaryType: type.type, dependencies: found)
                .forEach { found.insert($0) }
        }
        return found
    }

    private func parseAtomicType(_ data: JSON, type: String) throws -> [UInt8] {
        guard let abiType = ABIRawType(rawValue: type) else {
            throw ABIError.invalidValue
        }
        
        switch abiType {
        case .DynamicString:
            guard let value = data.stringValue?.web3.keccak256 else {
                throw ABIError.invalidValue
            }
            return try ABIEncoder.encodeRaw(value, forType: .FixedBytes(32)).bytes
        case .DynamicBytes:
            guard let value = data.stringValue.flatMap(Data.init(hex:))?.web3.keccak256 else {
                throw ABIError.invalidValue
            }
            return try ABIEncoder.encodeRaw(value, forType: .FixedBytes(32)).bytes
        case .FixedAddress, .FixedBytes:
            guard let value = data.stringValue else {
                throw ABIError.invalidValue
            }
            return try ABIEncoder.encodeRaw(value, forType: abiType).bytes
        case .FixedInt, .FixedUInt:
            if let value = data.stringValue {
                return try ABIEncoder.encodeRaw(value, forType: abiType).bytes
            } else if let value = data.doubleValue {
                return try ABIEncoder.encode(BigUInt(value)).bytes
            } else {
                throw ABIError.invalidValue
            }
        case .FixedBool:
            guard let value = data.boolValue else {
                throw ABIError.invalidValue
            }
            
            return try ABIEncoder.encode(BigUInt(value ? 1 : 0)).bytes
        case .DynamicArray(let nested):
            guard let value = data.arrayValue else {
                throw ABIError.invalidValue
            }
            
            let encoded = try value.flatMap { try parseAtomicType($0, type: nested.rawValue) }
            return Data(encoded).web3.keccak256.web3.bytes
        case .FixedArray(let nested, let count):
            guard let value = data.arrayValue else {
                throw ABIError.invalidValue
            }
            
            guard value.count == count else {
                throw ABIError.invalidValue
            }
            
            let encoded = try value.flatMap { try parseAtomicType($0, type: nested.rawValue) }
            return Data(encoded).web3.keccak256.web3.bytes
        case .Tuple:
            throw ABIError.invalidValue
        }
    }
}
