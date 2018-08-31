//
//  ABIRawType.swift
//  web3swift
//
//  Created by Matt Marshall on 16/03/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation
import BigInt

public enum ABIError: Error {
    case invalidSignature
    case invalidType
    case invalidValue
    case incorrectParameterCount
    case notCurrentlySupported
}

enum ABIRawType {
    case FixedUInt(Int)
    case FixedInt(Int)
    case FixedAddress
    case FixedBool
    case FixedBytes(Int)
    case DynamicBytes
    case DynamicString
    indirect case FixedArray(ABIRawType, Int)
    indirect case DynamicArray(ABIRawType)
    // TODO Function. Fixed. UFixed.
}

extension ABIRawType: RawRepresentable {
    
    var rawValue: String {
        switch self {
        case .FixedUInt(let size): return "uint\(size)"
        case .FixedInt(let size): return "int\(size)"
        case .FixedAddress: return "address"
        case .FixedBool: return "bool"
        case .FixedBytes(let size): return "bytes\(size)"
        case .DynamicBytes: return "bytes"
        case .DynamicString: return "string"
        case .FixedArray(let type, let size): return "\(type.rawValue)[\(size)]"
        case .DynamicArray(let type): return "\(type.rawValue)[]"
        }
    }
    
    var isDynamic: Bool {
        switch self {
        case .DynamicBytes, .DynamicString, .DynamicArray(_):
            return true
        default:
            return false
        }
    }
    
    var isArray: Bool {
        switch self {
        case .FixedArray(_, _), .DynamicArray(_):
            return true
        default:
            return false
        }
    }
    
    var size: Int {
        switch self {
        case .FixedUInt(let size), .FixedInt(let size):
            return size / 8
        case .FixedBytes(let size), .FixedArray(_, let size):
            return size
        case .DynamicArray(_):
            return -1
        default:
            return 0
        }
    }
    
    var memory: Int {
        switch self {
        case .FixedArray(let type, let size):
            return type.memory * size
        default:
            return 32
        }
    }
}
