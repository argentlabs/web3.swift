//
//  ERC20Responses.swift
//  web3swift
//
//  Created by Matt Marshall on 13/04/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation
import BigInt

public enum ERC20Responses {
    public struct nameResponse: ABIResponse, MulticallDecodableResponse {
        public static var types: [ABIType.Type] = [ String.self ]
        public let value: String
        
        public init?(values: [ABIDecoder.DecodedValue]) throws {
            self.value = try values[0].decoded()
        }
    }
    
    public struct symbolResponse: ABIResponse, MulticallDecodableResponse {
        public static var types: [ABIType.Type] = [ String.self ]
        public let value: String
        
        public init?(values: [ABIDecoder.DecodedValue]) throws {
            self.value = try values[0].decoded()
        }
    }
    
    public struct decimalsResponse: ABIResponse, MulticallDecodableResponse {
        public static var types: [ABIType.Type] = [ UInt8.self ]
        public let value: UInt8
        
        public init?(values: [ABIDecoder.DecodedValue]) throws {
            self.value = try values[0].decoded()
        }
    }

    public struct balanceResponse: ABIResponse, MulticallDecodableResponse {
        public static var types: [ABIType.Type] = [ BigUInt.self ]
        public let value: BigUInt
        
        public init?(values: [ABIDecoder.DecodedValue]) throws {
            self.value = try values[0].decoded()
        }
    }
}
