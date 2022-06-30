//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation

public struct Signature: Equatable {
    public let r: Data
    public let s: Data
    public let v: Int
    public let recoveryParam: Int
    let raw: Data
    
    public init(
        r: Data,
        s: Data,
        v: Int,
        recoveryParam: Int
    ) {
        self.r = r
        self.s = s
        self.v = v
        self.recoveryParam = recoveryParam
        self.raw = r + s + Data.init([UInt8(v)])
    }
    
    public init(
        raw: Data
    ) {
        self.raw = raw
        (self.r, self.s, self.v) = raw.extractRSV()
        self.recoveryParam = 1 - (self.v % 2)
    }
}

extension Data {
    func extractRSV() -> (Data, Data, Int) {
        guard count == 65 else {
            fatalError("Invalid usage: Need a correctly sized signature")
        }
        
        let r = subdata(in: 0..<32)
        let s = subdata(in: 32..<64)
        var v = Int(self[64])
        if v < 27 { // recid == v
            v += 27
        }
       
        return (r.web3.strippingZeroesFromBytes, s.web3.strippingZeroesFromBytes, v)
    }
}
