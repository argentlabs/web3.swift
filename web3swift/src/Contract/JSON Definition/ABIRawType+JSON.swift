//
//  ABIRawType+JSON.swift
//  web3swift
//
//  Created by Matt Marshall on 10/04/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation

extension ABIRawType {
    init?(rawValue: String) {
        // Specific match
        if rawValue == "uint" {
            self = ABIRawType.FixedUInt(256)
            return
        } else if rawValue == "int" {
            self = ABIRawType.FixedInt(256)
            return
        } else if rawValue == "address" {
            self = ABIRawType.FixedAddress
            return
        } else if rawValue == "bool" {
            self = ABIRawType.FixedBool
            return
        } else if rawValue == "bytes" {
            self = ABIRawType.DynamicBytes
            return
        }  else if rawValue == "string" {
            self = ABIRawType.DynamicString
            return
        }
        
        // Arrays
        let components = rawValue.components(separatedBy: CharacterSet(charactersIn: "[]"))
        if components.count == 3 && components[1].isEmpty {
            if let arrayType = ABIRawType(rawValue: components[0]) {
                self = ABIRawType.DynamicArray(arrayType)
                return
            }
        } else if components.count == 3 && !components[1].isEmpty {
            let num = String(components[1].filter { "0"..."9" ~= $0 })
            guard let int = Int(num) else { return nil }
            if let arrayType = ABIRawType(rawValue: components[0]) {
                self = ABIRawType.FixedArray(arrayType, int)
                return
            }
        }
        
        // Variable sizes
        if rawValue.starts(with: "uint") {
            let num = String(rawValue.filter { "0"..."9" ~= $0 })
            guard let int = Int(num) else { return nil }
            self = ABIRawType.FixedUInt(int)
            return
        } else if rawValue.starts(with: "int") {
            let num = String(rawValue.filter { "0"..."9" ~= $0 })
            guard let int = Int(num) else { return nil }
            self = ABIRawType.FixedInt(int)
            return
        } else if rawValue.starts(with: "bytes") {
            let num = String(rawValue.filter { "0"..."9" ~= $0 })
            guard let int = Int(num) else { return nil }
            self = ABIRawType.FixedBytes(int)
            return
        }
        
        return nil
    }
}
