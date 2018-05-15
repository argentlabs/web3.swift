//
//  KeccakExtensions.swift
//  web3swift
//
//  Created by Matt Marshall on 13/03/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation
import keccaktiny

public extension Data {
    public var keccak256: Data {
        let nsData = self as NSData
        let input = nsData.bytes.bindMemory(to: UInt8.self, capacity: self.count)
        let result = UnsafeMutablePointer<UInt8>.allocate(capacity: 32)
        keccak_256(result, 32, input, self.count)
        return Data(bytes: result, count: 32)
    }
}

public extension String {
    public var keccak256: Data {
        let data = self.data(using: .utf8) ?? Data()
        return data.keccak256
    }
    
    public var keccak256fromHex: Data {
        let data = self.hexData!
        return data.keccak256
    }
}
