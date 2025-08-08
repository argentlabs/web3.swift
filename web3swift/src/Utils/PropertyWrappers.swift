//
//  web3.swift
//  Copyright © Argent Labs Limited. All rights reserved.
//

import Foundation

@propertyWrapper
struct DataStr: Codable, Equatable, Hashable {
    private var value: Data

    init(wrappedValue: Data) {
        self.value = wrappedValue
    }

    init(_ value: Data) {
        self.init(wrappedValue: value)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let str = try container.decode(String.self)
        guard let data = Data(hex: str) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Data not in '0x' format")
        }
        self.value = data
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value.web3.hexString)
    }

    var wrappedValue: Data {
        get { value }
        set { value = newValue }
    }
}
