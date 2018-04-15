//
//  ERC20Responses.swift
//  web3swift
//
//  Created by Matt Marshall on 13/04/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation
import BigInt

enum ERC20Responses {
    struct nameResponse: ABIResponse {
        static var types: [ABIType.Type] = [ String.self ]
        let value: String
        
        init?(values: [String]) throws {
            self.value = try ABIDecoder.decode(values[0], to: String.self)
        }
    }
    
    struct symbolResponse: ABIResponse {
        static var types: [ABIType.Type] = [ String.self ]
        let value: String
        
        init?(values: [String]) throws {
            self.value = try ABIDecoder.decode(values[0], to: String.self)
        }
    }
    
    struct decimalsResponse: ABIResponse {
        static var types: [ABIType.Type] = [ BigUInt.self ]
        let value: BigUInt
        
        init?(values: [String]) throws {
            self.value = try ABIDecoder.decode(values[0], to: BigUInt.self)
        }
    }
    
    
    struct balanceResponse: ABIResponse {
        static var types: [ABIType.Type] = [ BigUInt.self ]
        let value: BigUInt
        
        init?(values: [String]) throws {
            self.value = try ABIDecoder.decode(values[0], to: BigUInt.self)
        }
    }
}
