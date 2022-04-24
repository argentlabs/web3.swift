//  Created by Rinat Enikeev on 23.04.2022.

import Foundation
import BigInt

public class ABIConstructorEncoder {
    private (set) var types: [ABIRawType] = []

    public func encode(_ value: ABIType, staticSize: Int? = nil) throws {
        let rawType = type(of: value).rawType
        let encoded = try ABIEncoder.encode(value, staticSize: staticSize)

        encodedValues.append(encoded)
        switch (staticSize, rawType) {
        case (let size?, .DynamicBytes):
            guard size <= 32 else {
                throw ABIError.invalidType
            }
            types.append(.FixedBytes(size))
        case (let size?, .FixedUInt):
            guard size <= 256 else {
                throw ABIError.invalidType
            }
            types.append(.FixedUInt(size))
        case (let size?, .FixedInt):
            guard size <= 256 else {
                throw ABIError.invalidType
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
    private let bytecode: Data

    public init(_ bytecode: Data) {
        self.bytecode = bytecode
    }

    public func encoded() throws -> Data {
        let allBytes = try encodedValues.encoded(isDynamic: false)
        var result = Data()
        result.append(bytecode)
        result.append(Data(allBytes))
        return result
    }
}
