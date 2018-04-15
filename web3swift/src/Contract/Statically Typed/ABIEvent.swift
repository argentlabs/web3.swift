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
    var transactionHash: String { get }
    init?(values: [String], transactionHash: String) throws
    
    static func checkValueCount(_ values: [String]) throws
    static func signature() throws -> String
}

extension ABIEvent {
    public static func checkValueCount(_ values: [String]) throws {
        guard values.count == Self.types.count else {
            print("Incorrect param count")
            throw ABIError.incorrectParameterCount
        }
    }
    
    public static func signature() throws -> String {
        let sig = try ABIEncoder.signature(name: Self.name, types: Self.types)
        return String(bytes: sig)
    }
}
