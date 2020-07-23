//
//  ABITuple.swift
//  web3swift
//
//  Created by Miguel on 21/07/2020.
//  Copyright © 2020 Argent Labs Limited. All rights reserved.
//

import Foundation

/// A Tuple is a set of sequential types encoded together
public protocol ABITupleDecodable {
    static var types: [ABIType.Type] { get }
    init?(values: [ABIType]) throws
}

public extension ABITupleDecodable {
    init?(data: String) throws {
        let decoded = try ABIDecoder.decodeData(data, types: Self.types)
        try self.init(values: decoded)
    }
}

public protocol ABITupleEncodable {
    var encodableValues: [ABIType] { get }
}

public protocol ABITuple: ABIType, ABITupleEncodable, ABITupleDecodable {}

