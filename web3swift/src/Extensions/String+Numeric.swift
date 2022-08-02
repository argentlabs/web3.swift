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
    
    var isAddress: Bool {
            let hexAddressPattern = #"(?=^0x[a-fA-F0-9]{40}$)"#
            return checkRegexMatching(pattern: hexAddressPattern)
    }
    
    private func checkRegexMatching(pattern: String) -> Bool {
        do {
            let passwordRegex = try NSRegularExpression(
                pattern: pattern,
                options: []
            )
            let sourceRange = NSRange(
                self.base.startIndex..<self.base.endIndex,
                in: self.base
            )
            let result = passwordRegex.matches(
                in: self.base,
                options: [],
                range: sourceRange
            )
            return !result.isEmpty
        } catch let error as NSError {
            print("Error matching regex: \(error.description)")
            return false
        }
    }
}
