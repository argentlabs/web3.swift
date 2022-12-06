//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation

public struct EthereumAddress: Codable, Hashable {
    public let value: String
    public static let zero: Self = "0x0000000000000000000000000000000000000000"

    public init(_ value: String) {
        self.value = value.lowercased()
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.value = try container.decode(String.self).lowercased()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }

    public static func == (lhs: EthereumAddress, rhs: EthereumAddress) -> Bool {
        lhs.value == rhs.value
    }
}

public extension EthereumAddress {
    func toChecksumAddress() -> String {
        let lowerCaseAddress = value.web3.noHexPrefix.lowercased()
        let arr = Array(lowerCaseAddress)
        let keccaf = Array(lowerCaseAddress.web3.keccak256.web3.hexString.web3.noHexPrefix)
        var result = "0x"
        for i in 0 ... lowerCaseAddress.count - 1 {
            if let val = Int(String(keccaf[i]), radix: 16), val >= 8 {
                result.append(arr[i].uppercased())
            } else {
                result.append(arr[i])
            }
        }
        return result
    }
}

extension EthereumAddress: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value)
    }
}
