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
    
    public func encode(_ value: ABIType, size staticSize: ABIFixedSizeDataType.Type? = nil) throws {
        guard let rawType = staticSize.flatMap(ABIRawType.init(type:)) ?? ABIRawType(type: type(of: value)) else {
            throw ABIError.invalidValue
        }
        
        encodedValues.append(try ABIEncoder.encode(value, staticSize: staticSize))
        types.append(rawType)
    }

    private var encodedValues = [ABIEncoder.EncodedValue]()

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
                head += try! ABIEncoder.encode(String(position), forType: ABIRawType.FixedInt(256)).encoded
                tail += $0.encoded
            } else {
                head += $0.encoded
            }
        }
        
        return head + tail
    }
    
    public func encoded() throws -> Data {
        let methodId = try ABIEncoder.methodId(name: name, types: types)
        let allBytes = methodId + calculateData()
        return Data(allBytes)
    }
}
