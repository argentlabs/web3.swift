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
            
        case UnicodeScalar(unicodeScalarLiteral:"0")...UnicodeScalar(unicodeScalarLiteral:"9"):
            return UInt8(digit.value - UnicodeScalar(unicodeScalarLiteral:"0").value)
            
        case UnicodeScalar(unicodeScalarLiteral:"a")...UnicodeScalar(unicodeScalarLiteral:"f"):
            return UInt8(digit.value - UnicodeScalar(unicodeScalarLiteral:"a").value + 0xa)
            
        case UnicodeScalar(unicodeScalarLiteral:"A")...UnicodeScalar(unicodeScalarLiteral:"F"):
            return UInt8(digit.value - UnicodeScalar(unicodeScalarLiteral:"A").value + 0xa)
            
        default:
            throw HexConversionError.invalidDigit
        }
    }

    static func byteArray(fromHex string: String, addingPadding addPadding: Bool = false) throws -> [UInt8] {
        var iterator = string.unicodeScalars.makeIterator()
        var byteArray: [UInt8] = []
        
        while let msn = iterator.next() {
            var lsn = iterator.next()
            if lsn == nil, addPadding == true {
                lsn = "0"
            }

            guard let lsn else {
                throw HexConversionError.stringNotEven
            }

            do {
                let convertedMsn = try convert(hexDigit: msn)
                let convertedLsn = try convert(hexDigit: lsn)
                byteArray += [convertedMsn << 4 | convertedLsn]
            } catch {
                throw error
            }
        }
        return byteArray
    }
}
