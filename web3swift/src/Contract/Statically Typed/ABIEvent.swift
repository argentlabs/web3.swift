//
//  ABIEvent.swift
//  web3swift
//
//  Created by Matt Marshall on 06/04/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation

public protocol ABIEvent {
    static var name: String { get }
    static var types: [ABIType.Type] { get }
    static var typesIndexed: [Bool] { get }
    var log: EthereumLog { get }
    init?(topics: [String], data: [ABIType], log: EthereumLog) throws
    
    static func checkParameters(_ topics: [String], _ data: [ABIType]) throws
    static func signature() throws -> String
}

extension ABIEvent {
    public static func checkParameters(_ topics: [String], _ data: [ABIType]) throws {
        let indexedCount = Self.typesIndexed.filter { $0 == true }.count
        let unindexedCount = Self.typesIndexed.filter { $0 == false }.count
        
        guard Self.typesIndexed.count == Self.types.count, topics.count == indexedCount, data.count == unindexedCount else {
            print("Incorrect param count")
            throw ABIError.incorrectParameterCount
        }
    }
    
    public static func signature() throws -> String {
        let sig = try ABIEncoder.signature(name: Self.name, types: Self.types)
        return String(bytes: sig)
    }
}
