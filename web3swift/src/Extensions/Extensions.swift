//
//  Extensions.swift
//  web3swift
//
//  Created by Miguel on 02/10/2019.
//  Copyright © 2019 Argent Labs Limited. All rights reserved.
//

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
    let base: Base
    init(_ base: Base) {
        self.base = base
    }
}

extension Data: Web3Extendable {}
extension String: Web3Extendable {}
