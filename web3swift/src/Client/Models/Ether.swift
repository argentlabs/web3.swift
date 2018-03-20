//
//  Ether.swift
//  web3swift
//
//  Created by Matt Marshall on 06/03/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation
import BigInt

public struct Ether {
    public static let kweiMultiplier: BigInt = 1_000
    public static let mweiMultiplier: BigInt = 1_000_000
    public static let gweiMultiplier: BigInt = 1_000_000_000
    public static let szaboMultiplier: BigInt = 1_000_000_000_000
    public static let finneyMultiplier: BigInt = 1_000_000_000_000_000
    public static let etherMultiplier: BigInt = 1_000_000_000_000_000_000
    
    let wei: BigInt
    
    init(wei: BigInt) {
        self.wei = wei
    }
    
    init(kwei: BigInt) {
        self.wei = kwei * Ether.kweiMultiplier
    }
    
    init(mwei: BigInt) {
        self.wei = mwei * Ether.mweiMultiplier
    }
    
    init(gwei: BigInt) {
        self.wei = gwei * Ether.gweiMultiplier
    }
    
    init(szabo: BigInt) {
        self.wei = szabo * Ether.szaboMultiplier
    }
    
    init(finney: BigInt) {
        self.wei = finney * Ether.finneyMultiplier
    }
    
    init(ether: BigInt) {
        self.wei = ether * Ether.etherMultiplier
    }

}

extension Ether: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let hexValue = try container.decode(String.self)
        if let intValue = BigInt(hexValue) {
            self.init(wei: intValue)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot convert string(hex) to BigInt")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.wei)
    }
}
