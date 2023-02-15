//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation
import BigInt

public struct EthereumAddress: Codable, Hashable {
    @available(*, deprecated, message: "Shouldn't rely on the actual String representation. Use asString() instead to get an unformatted representation")
    public var value: String {
        raw
    }
    private let raw: String
    public static let zero: Self = "0x0000000000000000000000000000000000000000"

    public init(_ value: String) {
        self.raw = value.lowercased()
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.raw = try container.decode(String.self).lowercased()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(raw)
    }

    public func hash(into hasher: inout Hasher) {
        guard let data = asData() else {
            return
        }
        hasher.combine(data)
    }

    public static func == (lhs: EthereumAddress, rhs: EthereumAddress) -> Bool {
        guard let lhsInt = lhs.asNumber(), let rhsInt = rhs.asNumber() else {
            return false
        }
        // Comparing Number representation avoids issues with lowercase and 0-padding
        return lhsInt == rhsInt
    }
}

public extension EthereumAddress {
    func asString() -> String {
        raw
    }

    func asNumber() -> BigUInt? {
        .init(hex: raw)
    }

    func asData() -> Data? {
        raw.web3.hexData
    }

    func toChecksumAddress() -> String {
        let lowerCaseAddress = raw.web3.noHexPrefix.lowercased()
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
