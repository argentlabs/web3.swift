//
//  ABIDecoder+Static.swift
//  web3swift
//
//  Created by Matt Marshall on 10/04/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation
import BigInt

extension ABIDecoder {
    public typealias RawABI = String
    public typealias ParsedABIEntry = String
    public typealias ABIEntry = [String]
    
    public static func decodeData(_ data: RawABI, types: [ABIType.Type]) throws -> [ABIType] {
        let rawTypes = types.compactMap { ABIRawType(type: $0) }
        guard rawTypes.count == types.count else {
            throw ABIError.incorrectParameterCount
        }
        
        let rawDecoded = try ABIDecoder.decodeData(data, types: rawTypes)
        guard rawDecoded.count == types.count else {
            throw ABIError.incorrectParameterCount
        }
        
        return try zip(rawDecoded, types).map { try ABIDecoder.buildType($0.0, type:$0.1) }
    }
    
    static func buildType(_ data: ABIEntry, type: ABIType.Type) throws -> ABIType {
        guard let rawType = ABIRawType(type: type) else {
            throw ABIError.invalidValue
        }
        
        let parser = try rawType.parser(type: type)
        return try parser(data)
    }
    
    public static func decode(_ data: ParsedABIEntry, to: String.Type) throws -> String {
        return data.stringValue
    }
    
    public static func decode(_ data: ParsedABIEntry, to: Bool.Type) throws -> Bool {
        return data == "0x01" ? true : false
    }
    
    public static func decode(_ data: ParsedABIEntry, to: EthereumAddress.Type) throws -> EthereumAddress {
        return EthereumAddress(data)
    }
    
    public static func decode(_ data: ParsedABIEntry, to: BigInt.Type) throws -> BigInt {
        guard let value = BigInt(hex: data) else { throw ABIError.invalidValue }
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
    
    public static func decode(_ data: [ParsedABIEntry], to: [EthereumAddress].Type) throws -> [EthereumAddress] {
        return data.map { EthereumAddress($0) }
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

extension ABIRawType {
    func parser(type: ABIType.Type) throws -> ([String]) throws -> ABIType {
        return { data in
            let first = data.first ?? ""
            switch type {
            case is String.Type:
                return try ABIDecoder.decode(first, to: String.self)
            case is Bool.Type:
                return try ABIDecoder.decode(first, to: Bool.self)
            case is EthereumAddress.Type:
                return try ABIDecoder.decode(first, to: EthereumAddress.self)
            case is BigInt.Type:
                return try ABIDecoder.decode(first, to: BigInt.self)
            case is BigUInt.Type:
                return try ABIDecoder.decode(first, to: BigUInt.self)
            case is UInt8.Type:
                return try ABIDecoder.decode(first, to: UInt16.self)
            case is UInt16.Type:
                return try ABIDecoder.decode(first, to: UInt16.self)
            case is UInt32.Type:
                return try ABIDecoder.decode(first, to: UInt32.self)
            case is UInt64.Type:
                return try ABIDecoder.decode(first, to: UInt64.self)
            case is URL.Type:
                return try ABIDecoder.decode(first, to: URL.self)
            case is ABIFixedSizeDataType.Type:
                return try ABIDecoder.decode(first, to: Data.self)
            case is Data.Type:
                return try ABIDecoder.decode(first, to: Data.self)
            case is Array<EthereumAddress>.Type:
                return try ABIDecoder.decode(data, to: [EthereumAddress].self)
            default:
                throw ABIError.invalidValue
            }
        }
        
    }
}
