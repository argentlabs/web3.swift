//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation

public protocol ABIFunctionEncodable {
    static var name: String { get }
    func encode(to encoder: ABIFunctionEncoder) throws
}

extension ABIFunctionEncodable {
    public func decode(
        _ data: Data,
        expectedTypes: [ABIType.Type],
        filteringEmptyEntries filterEmptyEntries: Bool = true
    ) throws -> [ABIDecoder.DecodedValue] {
        let encoder = ABIFunctionEncoder(Self.name)
        try encode(to: encoder)
        let rawTypes = encoder.types
        let methodId = String(hexFromBytes: try ABIFunctionEncoder.methodId(name: Self.name, types: rawTypes))
        var raw = data.web3.hexString

        guard raw.hasPrefix(methodId) else {
            throw ABIError.invalidSignature
        }
        raw = raw.replacingOccurrences(of: methodId, with: "")
        let decoded = try ABIDecoder.decodeData(raw, types: expectedTypes)
        let empty = decoded.flatMap { $0.entry.filter(\.isEmpty) }
        guard
            empty.count == 0 || !filterEmptyEntries,
            decoded.count == expectedTypes.count else {
            throw ABIError.invalidSignature
        }

        return decoded
    }
}
