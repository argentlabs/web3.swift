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
    
    public static func decodeData(_ data: RawABI, types: [ABIType.Type], asArray: Bool = false) throws -> [ABIType] {
        let rawTypes = types.map { $0.rawType }

        let rawDecoded = try ABIDecoder.decodeData(data, types: rawTypes, asArray: asArray)
        guard rawDecoded.count == types.count else {
            throw ABIError.incorrectParameterCount
        }
        
        return try zip(rawDecoded, types).map { try ABIDecoder.buildType($0.0, type:$0.1) }
    }
    
    public static func decodeDataArray<T : ABIType>(_ data: RawABI, type: T.Type) throws -> [T] {
        let rawDecoded = try ABIDecoder.decodeData(data, types: [.DynamicArray(T.rawType)], asArray: false)
        guard rawDecoded.count > 0 else {
            return []
        }
        
        let values = try rawDecoded[0].map { try type.parser([$0]) as! T }
        return values
    }
    
    static func buildType(_ data: ABIEntry, type: ABIType.Type) throws -> ABIType {
        return try type.parser(data)
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
    
    // MIQU generic array-based API
    
    public static func decode(_ data: [ParsedABIEntry], to: [EthereumAddress].Type) throws -> [EthereumAddress] {
        return data.map { EthereumAddress($0) }
    }
    
    public static func decode(_ data: [ParsedABIEntry], to: [BigUInt].Type) throws -> [BigUInt] {
        return data.compactMap(BigUInt.init(hex:))
    }
    
    public static func decode(_ data: [ParsedABIEntry], to: [BigInt].Type) throws -> [BigInt] {
        return data.compactMap(BigInt.init(hex:))
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
