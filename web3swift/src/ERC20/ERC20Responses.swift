//
//  web3.swift
//  Copyright © Argent Labs Limited. All rights reserved.
//

import BigInt
import Foundation

public enum ERC20Responses: Sendable {
    public struct nameResponse: ABIResponse, MulticallDecodableResponse {
        public static let types: [ABIType.Type] = [String.self]
        public let value: String

        public init?(values: [ABIDecoder.DecodedValue]) throws {
            self.value = try values[0].decoded()
        }
    }

    public struct symbolResponse: ABIResponse, MulticallDecodableResponse {
        public static let types: [ABIType.Type] = [String.self]
        public let value: String

        public init?(values: [ABIDecoder.DecodedValue]) throws {
            self.value = try values[0].decoded()
        }
    }

    public struct decimalsResponse: ABIResponse, MulticallDecodableResponse {
        public static let types: [ABIType.Type] = [UInt8.self]
        public let value: UInt8

        public init?(values: [ABIDecoder.DecodedValue]) throws {
            self.value = try values[0].decoded()
        }
    }

    public struct balanceResponse: ABIResponse, MulticallDecodableResponse {
        public static let types: [ABIType.Type] = [BigUInt.self]
        public let value: BigUInt

        public init?(values: [ABIDecoder.DecodedValue]) throws {
            self.value = try values[0].decoded()
        }
    }
}
