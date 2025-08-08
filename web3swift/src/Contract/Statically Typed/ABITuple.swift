//
//  web3.swift
//  Copyright © Argent Labs Limited. All rights reserved.
//

import Foundation

/// A Tuple is a set of sequential types encoded together
public protocol ABITupleDecodable: Sendable {
    static var types: [ABIType.Type] { get }
    init?(data: String) throws
    init?(values: [ABIDecoder.DecodedValue]) throws
}

public extension ABITupleDecodable {
    init?(data: String) throws {
        let decoded = try ABIDecoder.decodeData(data, types: Self.types)
        try self.init(values: decoded)
    }
}

public protocol ABITupleEncodable {
    var encodableValues: [ABIType] { get }
    func encode(to encoder: ABIFunctionEncoder) throws
}

public protocol ABITuple: ABIType, ABITupleEncodable, ABITupleDecodable {}
