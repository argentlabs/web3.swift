//
//  web3.swift
//  Copyright © Argent Labs Limited. All rights reserved.
//

import BigInt
import Foundation

public enum ABIError: Sendable, Error {
    case invalidSignature
    case invalidType
    case invalidValue
    case incorrectParameterCount
    case notCurrentlySupported
}

public enum ABIRawType: Sendable {
    case FixedUInt(Int)
    case FixedInt(Int)
    case FixedAddress
    case FixedBool
    case FixedBytes(Int)
    case DynamicBytes
    case DynamicString
    indirect case FixedArray(ABIRawType, Int)
    indirect case DynamicArray(ABIRawType)
    indirect case Tuple([ABIRawType])
}

extension ABIRawType: RawRepresentable {
    public init?(rawValue: String) {
        // Specific match
        if rawValue == "uint" {
            self = ABIRawType.FixedUInt(256)
            return
        } else if rawValue == "int" {
            self = ABIRawType.FixedInt(256)
            return
        } else if rawValue == "address" {
            self = ABIRawType.FixedAddress
            return
        } else if rawValue == "bool" {
            self = ABIRawType.FixedBool
            return
        } else if rawValue == "bytes" {
            self = ABIRawType.DynamicBytes
            return
        } else if rawValue == "string" {
            self = ABIRawType.DynamicString
            return
        }

        // Arrays
        let components = rawValue.components(separatedBy: CharacterSet(charactersIn: "[]"))
        if components.count == 3, components[1].isEmpty {
            if let arrayType = ABIRawType(rawValue: components[0]) {
                self = ABIRawType.DynamicArray(arrayType)
                return
            }
        } else if components.count == 3, !components[1].isEmpty {
            let num = String(components[1].filter { "0" ... "9" ~= $0 })
            guard let int = Int(num) else {
                return nil
            }
            if let arrayType = ABIRawType(rawValue: components[0]) {
                self = ABIRawType.FixedArray(arrayType, int)
                return
            }
        }

        // Variable sizes
        if rawValue.starts(with: "uint") {
            let num = String(rawValue.filter { "0" ... "9" ~= $0 })
            guard let int = Int(num) else {
                return nil
            }
            self = ABIRawType.FixedUInt(int)
            return
        } else if rawValue.starts(with: "int") {
            let num = String(rawValue.filter { "0" ... "9" ~= $0 })
            guard let int = Int(num) else {
                return nil
            }
            self = ABIRawType.FixedInt(int)
            return
        } else if rawValue.starts(with: "bytes") {
            let num = String(rawValue.filter { "0" ... "9" ~= $0 })
            guard let int = Int(num) else {
                return nil
            }
            self = ABIRawType.FixedBytes(int)
            return
        }

        return nil
    }

    public var rawValue: String {
        switch self {
        case let .FixedUInt(size): "uint\(size)"
        case let .FixedInt(size): "int\(size)"
        case .FixedAddress: "address"
        case .FixedBool: "bool"
        case let .FixedBytes(size): "bytes\(size)"
        case .DynamicBytes: "bytes"
        case .DynamicString: "string"
        case let .FixedArray(type, size): "\(type.rawValue)[\(size)]"
        case let .DynamicArray(type): "\(type.rawValue)[]"
        case let .Tuple(types): "(\(types.map(\.rawValue).joined(separator: ",")))"
        }
    }

    var isDynamic: Bool {
        switch self {
        case .DynamicBytes, .DynamicString, .DynamicArray:
            true
        case let .Tuple(types):
            !types.filter(\.isDynamic).isEmpty
        default:
            false
        }
    }

    var isArray: Bool {
        switch self {
        case .FixedArray, .DynamicArray:
            true
        default:
            false
        }
    }

    var isTuple: Bool {
        switch self {
        case .Tuple:
            true
        default:
            false
        }
    }

    var isPaddedInDynamic: Bool {
        switch self {
        case .FixedUInt, .FixedInt:
            true
        default:
            false
        }
    }

    var size: Int {
        switch self {
        case .FixedBool:
            8
        case .FixedAddress:
            160
        case let .FixedUInt(size), let .FixedInt(size):
            size / 8
        case let .FixedBytes(size), let .FixedArray(_, size):
            size
        case .DynamicArray:
            -1
        default:
            0
        }
    }

    var memory: Int {
        switch self {
        case let .FixedArray(type, size):
            type.memory * size
        case let .Tuple(types):
            types.map(\.memory).reduce(0, +)
        default:
            32
        }
    }
}
