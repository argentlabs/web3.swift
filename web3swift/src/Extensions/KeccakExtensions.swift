//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation
import keccaktiny

public extension Web3Extensions where Base == Data {
    var keccak256: Data {
        let result = UnsafeMutablePointer<UInt8>.allocate(capacity: 32)
        defer {
            result.deallocate()
        }
        let nsData = base as NSData
        let input = nsData.bytes.bindMemory(to: UInt8.self, capacity: base.count)
        keccak_256(result, 32, input, base.count)
        return Data(bytes: result, count: 32)
    }
}

public extension Web3Extensions where Base == String {
    var keccak256: Data {
        let data = base.data(using: .utf8) ?? Data()
        return data.web3.keccak256
    }

    var keccak256fromHex: Data {
        let data = base.web3.hexData!
        return data.web3.keccak256
    }
}
