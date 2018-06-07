//
//  ABIRawType+Static.swift
//  web3swift
//
//  Created by Matt Marshall on 10/04/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation
import BigInt

public protocol ABIType { }

extension String: ABIType { }
extension Bool: ABIType { }
extension EthereumAddress: ABIType { }
extension BigInt: ABIType { }
extension BigUInt: ABIType { }
extension Data: ABIType { }
// TODO (U)Double. Function. Array. Other Int sizes
extension Array: ABIType { }
extension UInt8: ABIType { }
extension UInt16: ABIType { }
extension UInt32: ABIType { }
extension UInt64: ABIType { }

public protocol ABIFixedSizeDataType : ABIType {
    static var fixedSize: Int { get }
}

public struct Data32 : ABIFixedSizeDataType {
    public static var fixedSize: Int {
        return 32
    }
}

extension ABIRawType {
    init?(type: ABIType.Type) {
        switch type {
        case is String.Type: self = ABIRawType.DynamicString
        case is Bool.Type: self = ABIRawType.FixedBool
        case is EthereumAddress.Type: self = ABIRawType.FixedAddress
        case is BigInt.Type: self = ABIRawType.FixedInt(256)
        case is BigUInt.Type: self = ABIRawType.FixedUInt(256)
        case is UInt8.Type: self = ABIRawType.FixedUInt(8)
        case is UInt16.Type: self = ABIRawType.FixedUInt(16)
        case is UInt32.Type: self = ABIRawType.FixedUInt(32)
        case is UInt64.Type: self = ABIRawType.FixedUInt(64)
        case is Data.Type: self = ABIRawType.DynamicBytes
        case is ABIFixedSizeDataType.Type:
            guard let fixed = type as? ABIFixedSizeDataType.Type else { return nil }
            self = ABIRawType.FixedBytes(fixed.fixedSize)
        default: return nil
        }
    }
}
