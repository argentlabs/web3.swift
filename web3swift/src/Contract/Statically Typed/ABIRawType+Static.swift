//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation
import BigInt

public protocol ABIType {
    static var rawType: ABIRawType { get }
    
    typealias ParserFunction = ([String]) throws -> ABIType
    static var parser: ParserFunction { get }
}

extension String: ABIType {
    public static var rawType: ABIRawType { .DynamicString }
    
    public static var parser: ParserFunction {
        return { data in
            let first = data.first ?? ""
            return try ABIDecoder.decode(first, to: String.self)
        }
    }
}

extension Bool: ABIType {
    public static var rawType: ABIRawType { .FixedBool }
    public static var parser: ParserFunction {
        return { data in
            let first = data.first ?? ""
            return try ABIDecoder.decode(first, to: Bool.self)
        }
    }
}

extension EthereumAddress: ABIType {
    public static var rawType: ABIRawType { .FixedAddress }
    public static var parser: ParserFunction {
        return { data in
            let first = data.first ?? ""
            return try ABIDecoder.decode(first, to: EthereumAddress.self)
        }
      }
}
extension BigInt: ABIType {
    public static var rawType: ABIRawType { .FixedInt(256) }
    public static var parser: ParserFunction {
        return { data in
            let first = data.first ?? ""
            return try ABIDecoder.decode(first, to: BigInt.self)
        }
    }
}

extension BigUInt: ABIType {
    public static var rawType: ABIRawType { .FixedUInt(256) }
    public static var parser: ParserFunction {
        return { data in
            let first = data.first ?? ""
            return try ABIDecoder.decode(first, to: BigUInt.self)
        }
    }
}

extension UInt8: ABIType {
    public static var rawType: ABIRawType {
    .FixedUInt(8) }
    public static var parser: ParserFunction {
        return { data in
            let first = data.first ?? ""
            return try ABIDecoder.decode(first, to: UInt8.self)
        }
    }
}

extension UInt16: ABIType {
    public static var rawType: ABIRawType { .FixedUInt(16) }
    public static var parser: ParserFunction {
        return { data in
            let first = data.first ?? ""
            return try ABIDecoder.decode(first, to: UInt16.self)
        }
    }
}

extension UInt32: ABIType {
    public static var rawType: ABIRawType { .FixedUInt(32) }
    public static var parser: ParserFunction {
        return { data in
            let first = data.first ?? ""
            return try ABIDecoder.decode(first, to: UInt32.self)
        }
    }
}

extension UInt64: ABIType {
    public static var rawType: ABIRawType { .FixedUInt(64) }
    public static var parser: ParserFunction {
        return { data in
            let first = data.first ?? ""
            return try ABIDecoder.decode(first, to: UInt64.self)
        }
    }
}

extension URL : ABIType {
    public static var rawType: ABIRawType { .DynamicBytes }
    public static var parser: ParserFunction {
        return { data in
            let first = data.first ?? ""
            return try ABIDecoder.decode(first, to: URL.self)
        }
    }
}

extension ABITuple {
    public static var rawType: ABIRawType {
        .Tuple(Self.types.map { $0.rawType })
    }
    public static var parser: ParserFunction {
        return { data in
            let values = data.map { ABIDecoder.DecodedValue(entry: [$0]) }
            guard let decoded = try? self.init(values: values) else {
                throw ABIError.invalidValue
            }

            return decoded
        }
    }
}

// TODO: Other Int sizes

fileprivate let DataParser: ABIType.ParserFunction = { data in
    let first = data.first ?? ""
    return try ABIDecoder.decode(first, to: Data.self)
}

extension Data: ABIType {
    public static var rawType: ABIRawType { .DynamicBytes }
    public static var parser: ParserFunction = DataParser
}

// When decoding it's easier to specify a type, instead of type + static size
public protocol ABIStaticSizeDataType: ABIType {}

public struct Data1: ABIStaticSizeDataType {
    public static var rawType: ABIRawType {
        .FixedBytes(1)
    }
    
    public static var parser: ParserFunction = DataParser
}

public struct Data2: ABIStaticSizeDataType {
    public static var rawType: ABIRawType {
        .FixedBytes(2)
    }
    
    public static var parser: ParserFunction = DataParser
}

public struct Data3: ABIStaticSizeDataType {
    public static var rawType: ABIRawType {
        .FixedBytes(3)
    }
    
    public static var parser: ParserFunction = DataParser
}

public struct Data4: ABIStaticSizeDataType {
    public static var rawType: ABIRawType {
        .FixedBytes(4)
    }
    
    public static var parser: ParserFunction = DataParser
}

public struct Data5: ABIStaticSizeDataType {
    public static var rawType: ABIRawType {
        .FixedBytes(5)
    }
    
    public static var parser: ParserFunction = DataParser
}

public struct Data6: ABIStaticSizeDataType {
    public static var rawType: ABIRawType {
        .FixedBytes(6)
    }
    
    public static var parser: ParserFunction = DataParser
}

public struct Data7: ABIStaticSizeDataType {
    public static var rawType: ABIRawType {
        .FixedBytes(7)
    }
    
    public static var parser: ParserFunction = DataParser
}

public struct Data8: ABIStaticSizeDataType {
    public static var rawType: ABIRawType {
        .FixedBytes(8)
    }
    
    public static var parser: ParserFunction = DataParser
}

public struct Data9: ABIStaticSizeDataType {
    public static var rawType: ABIRawType {
        .FixedBytes(9)
    }
    
    public static var parser: ParserFunction = DataParser
}

public struct Data10: ABIStaticSizeDataType {
    public static var rawType: ABIRawType {
        .FixedBytes(10)
    }
    
    public static var parser: ParserFunction = DataParser
}

public struct Data11: ABIStaticSizeDataType {
    public static var rawType: ABIRawType {
        .FixedBytes(11)
    }
    
    public static var parser: ParserFunction = DataParser
}

public struct Data12: ABIStaticSizeDataType {
    public static var rawType: ABIRawType {
        .FixedBytes(12)
    }
    
    public static var parser: ParserFunction = DataParser
}

public struct Data13: ABIStaticSizeDataType {
    public static var rawType: ABIRawType {
        .FixedBytes(13)
    }
    
    public static var parser: ParserFunction = DataParser
}

public struct Data14: ABIStaticSizeDataType {
    public static var rawType: ABIRawType {
        .FixedBytes(14)
    }
    
    public static var parser: ParserFunction = DataParser
}

public struct Data15: ABIStaticSizeDataType {
    public static var rawType: ABIRawType {
        .FixedBytes(15)
    }
    
    public static var parser: ParserFunction = DataParser
}

public struct Data16: ABIStaticSizeDataType {
    public static var rawType: ABIRawType {
        .FixedBytes(16)
    }
    
    public static var parser: ParserFunction = DataParser
}

public struct Data17: ABIStaticSizeDataType {
    public static var rawType: ABIRawType {
        .FixedBytes(17)
    }
    
    public static var parser: ParserFunction = DataParser
}

public struct Data18: ABIStaticSizeDataType {
    public static var rawType: ABIRawType {
        .FixedBytes(18)
    }
    
    public static var parser: ParserFunction = DataParser
}

public struct Data19: ABIStaticSizeDataType {
    public static var rawType: ABIRawType {
        .FixedBytes(19)
    }
    
    public static var parser: ParserFunction = DataParser
}

public struct Data20: ABIStaticSizeDataType {
    public static var rawType: ABIRawType {
        .FixedBytes(20)
    }
    
    public static var parser: ParserFunction = DataParser
}

public struct Data21: ABIStaticSizeDataType {
    public static var rawType: ABIRawType {
        .FixedBytes(21)
    }
    
    public static var parser: ParserFunction = DataParser
}

public struct Data22: ABIStaticSizeDataType {
    public static var rawType: ABIRawType {
        .FixedBytes(22)
    }
    
    public static var parser: ParserFunction = DataParser
}

public struct Data23: ABIStaticSizeDataType {
    public static var rawType: ABIRawType {
        .FixedBytes(23)
    }
    
    public static var parser: ParserFunction = DataParser
}

public struct Data24: ABIStaticSizeDataType {
    public static var rawType: ABIRawType {
        .FixedBytes(24)
    }
    
    public static var parser: ParserFunction = DataParser
}

public struct Data25: ABIStaticSizeDataType {
    public static var rawType: ABIRawType {
        .FixedBytes(25)
    }
    
    public static var parser: ParserFunction = DataParser
}

public struct Data26: ABIStaticSizeDataType {
    public static var rawType: ABIRawType {
        .FixedBytes(26)
    }
    
    public static var parser: ParserFunction = DataParser
}

public struct Data27: ABIStaticSizeDataType {
    public static var rawType: ABIRawType {
        .FixedBytes(27)
    }
    
    public static var parser: ParserFunction = DataParser
}

public struct Data28: ABIStaticSizeDataType {
    public static var rawType: ABIRawType {
        .FixedBytes(28)
    }
    
    public static var parser: ParserFunction = DataParser
}

public struct Data29: ABIStaticSizeDataType {
    public static var rawType: ABIRawType {
        .FixedBytes(29)
    }
    
    public static var parser: ParserFunction = DataParser
}

public struct Data30: ABIStaticSizeDataType {
    public static var rawType: ABIRawType {
        .FixedBytes(30)
    }
    
    public static var parser: ParserFunction = DataParser
}

public struct Data31: ABIStaticSizeDataType {
    public static var rawType: ABIRawType {
        .FixedBytes(31)
    }
    
    public static var parser: ParserFunction = DataParser
}

public struct Data32: ABIStaticSizeDataType {
    public static var rawType: ABIRawType {
        .FixedBytes(32)
    }
    
    public static var parser: ParserFunction = DataParser
}

public struct ABIArray<T: ABIType>: ABIType {
    let values: [T]
    
    public init(values: [T]) {
        self.values = values
    }
    public static var rawType: ABIRawType {
        .DynamicArray(T.rawType)
    }
    
    public static var parser: ParserFunction {
        return T.parser
    }
}
