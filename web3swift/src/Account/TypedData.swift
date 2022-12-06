//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import BigInt
import Foundation
import GenericJSON

/// A type value description
public struct TypedVariable: Codable, Equatable {
    public var name: String
    public var type: String

    public init(
        name: String,
        type: String
    ) {
        self.name = name
        self.type = type
    }
}

/// Typed data as per EIP712
public struct TypedData: Codable, Equatable {
    public var types: [String: [TypedVariable]]
    public var primaryType: String
    public var domain: JSON
    public var message: JSON

    public init(
        types: [String: [TypedVariable]],
        primaryType: String,
        domain: JSON,
        message: JSON
    ) {
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

            // Decomposit the type if it is array type
            let components = variable.type.components(separatedBy: CharacterSet(charactersIn: "[]"))
            let parsedType = components[0]

            // Check the type is a custom type
            if types[parsedType] != nil {
                guard let json = data[variable.name] else {
                    throw ABIError.invalidValue
                }

                // If is custom type array, recursively encode the array
                if components.count == 3, components[1].isEmpty {
                    let encoded = try json.arrayValue!.flatMap { try encodeData(data: $0, type: parsedType).web3.keccak256.web3.bytes }

                    return Data(encoded).web3.keccak256.web3.bytes
                } else if components.count == 3, !components[1].isEmpty {
                    let num = String(components[1].filter { "0" ... "9" ~= $0 })
                    guard let int = Int(num), int == json.arrayValue?.count ?? 0 else {
                        throw ABIError.invalidValue
                    }

                    let encoded = try json.arrayValue!.flatMap { try encodeData(data: $0, type: parsedType) }
                    return Data(encoded).web3.keccak256.web3.bytes
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

    private func getParsedType(primaryType: String) -> String {
        // Decomposit the type if it is an array type
        let components = primaryType.components(separatedBy: CharacterSet(charactersIn: "[]"))
        let parsedType = components[0]

        return parsedType
    }

    private func findDependencies(primaryType: String, dependencies: Set<String> = Set<String>()) -> Set<String> {
        var found = dependencies

        let parsedType = getParsedType(primaryType: primaryType)

        guard !found.contains(parsedType),
              let primaryTypes = types[parsedType] else {
            return found
        }
        found.insert(parsedType)
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
        case let .DynamicArray(nested):
            guard let value = data.arrayValue else {
                throw ABIError.invalidValue
            }

            let encoded = try value.flatMap { try parseAtomicType($0, type: nested.rawValue) }

            return Data(encoded).web3.keccak256.web3.bytes
        case let .FixedArray(nested, count):
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
