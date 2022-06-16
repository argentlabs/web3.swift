//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation

public struct EthereumAddress: Codable, Hashable {
    public let value: String
    public static let zero = EthereumAddress("0x0000000000000000000000000000000000000000")
    
    public init(_ value: String) {
        self.value = value.lowercased()
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.value = try container.decode(String.self).lowercased()
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.value)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.value)
    }
    
    public static func == (lhs: EthereumAddress, rhs: EthereumAddress) -> Bool {
        return lhs.value == rhs.value
    }
}
