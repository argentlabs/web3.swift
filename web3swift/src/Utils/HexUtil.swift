//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation

enum HexConversionError: Error {
    case invalidDigit
    case stringNotEven
}

class HexUtil {

    private static func convert(hexDigit digit: UnicodeScalar) throws -> UInt8 {
        switch digit {

        case UnicodeScalar(unicodeScalarLiteral: "0")...UnicodeScalar(unicodeScalarLiteral: "9"):
            return UInt8(digit.value - UnicodeScalar(unicodeScalarLiteral: "0").value)

        case UnicodeScalar(unicodeScalarLiteral: "a")...UnicodeScalar(unicodeScalarLiteral: "f"):
            return UInt8(digit.value - UnicodeScalar(unicodeScalarLiteral: "a").value + 0xa)

        case UnicodeScalar(unicodeScalarLiteral: "A")...UnicodeScalar(unicodeScalarLiteral: "F"):
            return UInt8(digit.value - UnicodeScalar(unicodeScalarLiteral: "A").value + 0xa)

        default:
            throw HexConversionError.invalidDigit
        }
    }

    static func byteArray(fromHex string: String) throws -> [UInt8] {
        var iterator = string.unicodeScalars.makeIterator()
        var byteArray: [UInt8] = []

        while let msn = iterator.next() {
            if let lsn = iterator.next() {
                do {
                    let convertedMsn = try convert(hexDigit: msn)
                    let convertedLsn = try convert(hexDigit: lsn)
                    byteArray += [ convertedMsn << 4 | convertedLsn ]
                } catch {
                    throw error
                }
            } else {
                throw HexConversionError.stringNotEven
            }
        }
        return byteArray
    }
}
