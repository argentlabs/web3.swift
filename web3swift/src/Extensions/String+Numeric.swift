//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation

public extension Web3Extensions where Base == String {
    var isNumeric: Bool {
        guard !base.isEmpty else {
            return false
        }

        guard !base.starts(with: "-") else {
            return String(base.dropFirst()).web3.isNumeric
        }

        return base.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
    }
}
