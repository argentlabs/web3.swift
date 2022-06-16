//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation

@propertyWrapper
struct DataStr: Codable, Equatable, Hashable {
    private var value: Data

    public init(wrappedValue: Data) {
        self.value = wrappedValue
    }

    public init(_ value: Data) {
        self.init(wrappedValue: value)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let str = try container.decode(String.self)
        guard let data = Data(hex: str) else { throw DecodingError.dataCorruptedError(in: container, debugDescription: "Data not in '0x' format") }
        self.value = data
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value.web3.hexString)
    }

    public var wrappedValue: Data {
        get { value }
        set { self.value = newValue }
    }

}
