//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import BigInt
import Foundation

public struct EthereumAddress: Codable, Hashable {
    private var raw: BigUInt
    public var value: String {
        raw.web3.hexString(paddingToSize: Self.bytesSize)
    }

    public static let bytesSize: Int = 20
    public static let zero: Self = "0x0000000000000000000000000000000000000000"

    public init(_ value: String) {
        self.raw = BigUInt(hex: value) ?? .zero
    }

    public init(raw: BigUInt) {
        self.raw = raw
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let encoded = try container.decode(String.self).lowercased()
        self.raw = .init(hex: encoded) ?? .zero
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value.lowercased())
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(raw)
    }

    public static func == (lhs: EthereumAddress, rhs: EthereumAddress) -> Bool {
        lhs.raw == rhs.raw
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
