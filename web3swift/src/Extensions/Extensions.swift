//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import BigInt
import Foundation

public protocol Web3Extendable {
    associatedtype T
    var web3: T { get }
}

public extension Web3Extendable {
    var web3: Web3Extensions<Self> {
        return Web3Extensions(self)
    }
}

public struct Web3Extensions<Base> {
    internal(set) public var base: Base
    init(_ base: Base) {
        self.base = base
    }
}

extension Data: Web3Extendable {}
extension String: Web3Extendable {}
extension BigUInt: Web3Extendable {}
extension BigInt: Web3Extendable {}
extension Int: Web3Extendable {}
