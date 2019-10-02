//
//  KeccakExtensions.swift
//  web3swift
//
//  Created by Matt Marshall on 13/03/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation
import keccaktiny

public extension Web3Extensions where Base == Data {
    var keccak256: Data {
        let nsData = self.base as NSData
        let input = nsData.bytes.bindMemory(to: UInt8.self, capacity: self.base.count)
        let result = UnsafeMutablePointer<UInt8>.allocate(capacity: 32)
        keccak_256(result, 32, input, self.base.count)
        return Data(bytes: result, count: 32)
    }
}

public extension Web3Extensions where Base == String {
    var keccak256: Data {
        let data = self.base.data(using: .utf8) ?? Data()
        return data.web3.keccak256
    }
    
    var keccak256fromHex: Data {
        let data = self.base.hexData!
        return data.web3.keccak256
    }
}
