//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation
import BigInt

extension ABIDecoder {
    public typealias RawABI = String
    public typealias ParsedABIEntry = String
    public typealias ABIEntry = [String]

    public struct DecodedValue {
        let entry: ABIEntry

        public func decoded<T: ABIType>() throws -> T {
            let parse = T.parser
            guard let decoded = try parse(entry) as? T else {
                throw ABIError.invalidValue
            }
            return decoded
        }

        public func decodedArray<T: ABIType>() throws -> [T] {
            let parse = T.parser
            let parsed = try entry.map { try parse([$0]) }.compactMap { $0 as? T }

            guard entry.count == parsed.count else {
                throw ABIError.invalidValue
            }

            return parsed
        }

        public func decodedTupleArray<T: ABITuple>() throws -> [T] {
            let parse = T.parser

            let tupleElements = T.types.count
            let size = entry.count / tupleElements

            var parsed = [T]()
            var leftElements = entry
            while leftElements.count >= tupleElements {
                let slice = Array(leftElements[0..<tupleElements])
                if let abc = try parse(slice) as? T {
                    parsed.append(abc)
                }
                leftElements = Array(leftElements.dropFirst(tupleElements))
            }

            guard parsed.count == size else {
                throw ABIError.invalidValue
            }

            return parsed
        }
    }

    public static func decodeData(_ data: RawABI, types: [ABIType.Type], asArray: Bool = false) throws -> [DecodedValue] {
        let rawTypes = types.map { $0.rawType }

        let rawDecoded = try ABIDecoder.decodeData(data, types: rawTypes, asArray: asArray)
        guard rawDecoded.count == types.count else {
            throw ABIError.incorrectParameterCount
        }

        return rawDecoded.map(DecodedValue.init)
    }

    public static func decode(_ data: ParsedABIEntry, to: String.Type) throws -> String {
        return data.web3.stringValue
    }

    public static func decode(_ data: ParsedABIEntry, to: Bool.Type) throws -> Bool {
        if data == "0x01"{
            return true
        } else if data == "0x00" {
            return false
        } else {
            throw ABIError.invalidValue
        }
    }

    public static func decode(_ data: ParsedABIEntry, to: EthereumAddress.Type) throws -> EthereumAddress {
        let address = EthereumAddress(data)
        guard address.value.hasPrefix("0x") else {
            throw ABIError.invalidValue
        }

        return address
    }

    public static func decode(_ data: ParsedABIEntry, to: BigInt.Type) throws -> BigInt {
        guard let value = data.web3.hexData.map(BigInt.init(twosComplement:)) else { throw ABIError.invalidValue }
        return value
    }

    public static func decode(_ data: ParsedABIEntry, to: BigUInt.Type) throws -> BigUInt {
        guard let value = BigUInt(hex: data) else { throw ABIError.invalidValue }
        return value
    }

    public static func decode(_ data: ParsedABIEntry, to: UInt8.Type) throws -> UInt8 {
        guard let value = BigUInt(hex: data) else { throw ABIError.invalidValue }
        guard value.bitWidth <= 8 else { throw ABIError.invalidValue }
        return UInt8(value)
    }

    public static func decode(_ data: ParsedABIEntry, to: UInt16.Type) throws -> UInt16 {
        guard let value = BigUInt(hex: data) else { throw ABIError.invalidValue }
        guard value.bitWidth <= 16 else { throw ABIError.invalidValue }
        return UInt16(value)
    }

    public static func decode(_ data: ParsedABIEntry, to: UInt32.Type) throws -> UInt32 {
        guard let value = BigUInt(hex: data) else { throw ABIError.invalidValue }
        guard value.bitWidth <= 32 else { throw ABIError.invalidValue }
        return UInt32(value)
    }

    public static func decode(_ data: ParsedABIEntry, to: UInt64.Type) throws -> UInt64 {
        guard let value = BigUInt(hex: data) else { throw ABIError.invalidValue }
        guard value.bitWidth <= 64 else { throw ABIError.invalidValue }
        return UInt64(value)
    }

    public static func decode(_ data: ParsedABIEntry, to: URL.Type) throws -> URL {
        guard let string = try? ABIDecoder.decode(data, to: String.self) else {
            throw ABIError.invalidValue
        }
        let filtered = string.trimmingCharacters(in: CharacterSet(charactersIn: "\0"))
        guard let url = URL(string: filtered) else {
            throw ABIError.invalidValue
        }

        return url
    }

    public static func decode(_ data: ParsedABIEntry, to: Data.Type) throws -> Data {
        guard let data = Data(hex: data) else { throw ABIError.invalidValue }
        return data
    }

}
