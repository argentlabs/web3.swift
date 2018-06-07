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

public struct Data1 : ABIFixedSizeDataType {
    public static var fixedSize: Int {
        return 1
    }
}

public struct Data2 : ABIFixedSizeDataType {
    public static var fixedSize: Int {
        return 2
    }
}

public struct Data3 : ABIFixedSizeDataType {
    public static var fixedSize: Int {
        return 3
    }
}

public struct Data4 : ABIFixedSizeDataType {
    public static var fixedSize: Int {
        return 4
    }
}

public struct Data5 : ABIFixedSizeDataType {
    public static var fixedSize: Int {
        return 5
    }
}

public struct Data6 : ABIFixedSizeDataType {
    public static var fixedSize: Int {
        return 6
    }
}

public struct Data7 : ABIFixedSizeDataType {
    public static var fixedSize: Int {
        return 7
    }
}
public struct Data8 : ABIFixedSizeDataType {
    public static var fixedSize: Int {
        return 8
    }
}

public struct Data9 : ABIFixedSizeDataType {
    public static var fixedSize: Int {
        return 9
    }
}

public struct Data10 : ABIFixedSizeDataType {
    public static var fixedSize: Int {
        return 10
    }
}

public struct Data11 : ABIFixedSizeDataType {
    public static var fixedSize: Int {
        return 11
    }
}

public struct Data12 : ABIFixedSizeDataType {
    public static var fixedSize: Int {
        return 12
    }
}

public struct Data13 : ABIFixedSizeDataType {
    public static var fixedSize: Int {
        return 13
    }
}

public struct Data14 : ABIFixedSizeDataType {
    public static var fixedSize: Int {
        return 14
    }
}

public struct Data15 : ABIFixedSizeDataType {
    public static var fixedSize: Int {
        return 15
    }
}

public struct Data16 : ABIFixedSizeDataType {
    public static var fixedSize: Int {
        return 16
    }
}

public struct Data17 : ABIFixedSizeDataType {
    public static var fixedSize: Int {
        return 17
    }
}

public struct Data18 : ABIFixedSizeDataType {
    public static var fixedSize: Int {
        return 18
    }
}

public struct Data19 : ABIFixedSizeDataType {
    public static var fixedSize: Int {
        return 19
    }
}

public struct Data20 : ABIFixedSizeDataType {
    public static var fixedSize: Int {
        return 20
    }
}
public struct Data21 : ABIFixedSizeDataType {
    public static var fixedSize: Int {
        return 21
    }
}

public struct Data22 : ABIFixedSizeDataType {
    public static var fixedSize: Int {
        return 22
    }
}
public struct Data23 : ABIFixedSizeDataType {
    public static var fixedSize: Int {
        return 23
    }
}
public struct Data24 : ABIFixedSizeDataType {
    public static var fixedSize: Int {
        return 24
    }
}

public struct Data25 : ABIFixedSizeDataType {
    public static var fixedSize: Int {
        return 25
    }
}
public struct Data26 : ABIFixedSizeDataType {
    public static var fixedSize: Int {
        return 26
    }
}

public struct Data27 : ABIFixedSizeDataType {
    public static var fixedSize: Int {
        return 27
    }
}

public struct Data28 : ABIFixedSizeDataType {
    public static var fixedSize: Int {
        return 28
    }
}

public struct Data29 : ABIFixedSizeDataType {
    public static var fixedSize: Int {
        return 29
    }
}

public struct Data30 : ABIFixedSizeDataType {
    public static var fixedSize: Int {
        return 30
    }
}

public struct Data31 : ABIFixedSizeDataType {
    public static var fixedSize: Int {
        return 31
    }
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
