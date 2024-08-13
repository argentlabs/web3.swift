//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation

public enum ERC1271Responses {
    public struct isValidResponse: ABIResponse {
        // bytes4(keccak256("isValidSignature(bytes32,bytes)")
        static let MAGICVALUE = Data(hex: "0x1626ba7e")

        public static var types: [ABIType.Type] = [EitherBoolOrData4.self]

        public let isValid: Bool

        public init?(values: [ABIDecoder.DecodedValue]) throws {
            // It seems there are some confusion on the original EIP thread on github.
            // Some reference the return type as bool and others as byte4 (with the magic value)
            // so we'll try parsing both types, though byte4 parsing is what's actually
            // on the finalised document.
            switch try values[0].decoded() as EitherBoolOrData4 {
            case let .bool(bool):
                self.isValid = bool
            case let .data(data):
                self.isValid = data == Self.MAGICVALUE
            }
        }
    }

    // This will map the result to either a Bool value or a Data with 4 bytes
    private enum EitherBoolOrData4: ABIType {
        // Both cases return 32 bytes of data
        public static var rawType: ABIRawType { .FixedBytes(32) }

        public static var parser: ParserFunction {
            { data in
                switch data.first ?? "" {
                case "0x0000000000000000000000000000000000000000000000000000000000000000":
                    return EitherBoolOrData4.bool(false)
                case "0x0000000000000000000000000000000000000000000000000000000000000001":
                    return EitherBoolOrData4.bool(true)
                case let data:
                    return EitherBoolOrData4.data(try ABIDecoder.decode(data, to: Data.self).web3.bytes4)
                }
            }
        }

        case bool(Bool)
        case data(Data)
    }
}
