//
//  String+Numeric.swift
//  web3swift
//
//  Created by Matt Marshall on 13/03/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation

public extension Web3Extensions where Base == String {
    var isNumeric: Bool {
        return !base.isEmpty && base.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
    }
}
