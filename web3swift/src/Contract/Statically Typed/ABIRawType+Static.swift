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
// TODO (U)Double. Function. Array. Other Int sizes. Fixed binary type (byte<M>)
extension Array: ABIType { }

extension ABIRawType {
    init?(type: ABIType.Type) {
        switch type {
        case is String.Type: self = ABIRawType.DynamicString
        case is Bool.Type: self = ABIRawType.FixedBool
        case is EthereumAddress.Type: self = ABIRawType.FixedAddress
        case is BigInt.Type: self = ABIRawType.FixedInt(256)
        case is BigUInt.Type: self = ABIRawType.FixedUInt(256)
        case is Data.Type: self = ABIRawType.DynamicBytes
        default: return nil
        }
    }
}
