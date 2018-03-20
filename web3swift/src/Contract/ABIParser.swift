//
//  ABIParser.swift
//  web3swift
//
//  Created by Matt Marshall on 16/03/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation

struct ABIParsedType {
    var name: String
    var isArray: Bool = false
    var arrayType: String? = nil
    var size: Int = 0
    var memory: Int = 0
    var isDynamic: Bool = false
    
    init(name: String) {
        self.name = name
    }
}

class ABIParser {
    static func normalizeType(type: String) -> String {
        if type == "int" || type == "uint" {
            return type + "256"
        }
        return type
    }
    
    static func parseType(type: String) throws -> ABIParsedType {
        
        var parsed = ABIParsedType(name: type)
        
        let components = type.components(separatedBy: CharacterSet.init(charactersIn: "[]"))
        // if type is an array
        if components.count == 3 {
            let arrayType = try parseType(type: components[0])
            parsed.isArray = true
            parsed.arrayType = components[0]
            if components[1].isEmpty {
                parsed.size = -1
            } else if let int = Int(components[1]) {
                parsed.size = int
            } else {
                throw EthereumContractError.unknownError
            }
            
            parsed.memory = parsed.size < 0 ? 32 : arrayType.memory * parsed.size
            parsed.isDynamic = components[1].isEmpty ? true : arrayType.isDynamic
        } else {
            parsed.isArray = false
            parsed.memory = 32
            if type.hasPrefix("int") || type.hasPrefix("uint") {
                let num = String(type.filter { "0"..."9" ~= $0 })
                guard let int = Int(num) else { throw EthereumContractError.unknownError }
                parsed.size = int / 8
            }
            if type.hasPrefix("bytes") && type != "bytes" {
                let num = String(type.filter { "0"..."9" ~= $0 })
                guard let int = Int(num) else { throw EthereumContractError.unknownError }
                parsed.size = int
            }
            if type == "string" || type == "bytes" {
                parsed.isDynamic = true
            }
        }
        return parsed
    }
    
    static func isDynamic(type: String) -> Bool {
        
        if type == "string" || type == "bytes" {
            return true
        }
        let components = type.components(separatedBy: CharacterSet.init(charactersIn: "[]"))
        if components.count == 3 && (components[0].isEmpty || isDynamic(type: components[0])) {
            return true
        }
        return false
    }
    
    static func isArray(type: String) -> Bool {
        return type.components(separatedBy: CharacterSet.init(charactersIn: "[]")).count == 3
    }
}
