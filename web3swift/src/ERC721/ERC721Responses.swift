//
//  ERC721Responses.swift
//  web3swift
//
//  Created by Miguel on 09/05/2019.
//  Copyright © 2019 Argent Labs Limited. All rights reserved.
//

import Foundation
import BigInt

public enum ERC721Responses {
    public struct balanceResponse: ABIResponse {
        public static var types: [ABIType.Type] = [ BigUInt.self ]
        public let value: BigUInt
        
        public init?(values: [ABIType]) throws {
            self.value = try values[0].decoded()
        }
    }
    
    public struct ownerResponse: ABIResponse {
        public static var types: [ABIType.Type] = [ EthereumAddress.self ]
        public let value: EthereumAddress
        
        public init?(values: [ABIType]) throws {
            self.value = try values[0].decoded()
        }
    }
}

public enum ERC721MetadataResponses {
    public struct nameResponse: ABIResponse {
        public static var types: [ABIType.Type] = [ String.self ]
        public let value: String
        
        public init?(values: [ABIType]) throws {
            self.value = try values[0].decoded()
        }
    }
    
    public struct symbolResponse: ABIResponse {
        public static var types: [ABIType.Type] = [ String.self ]
        public let value: String
        
        public init?(values: [ABIType]) throws {
            self.value = try values[0].decoded()
        }
    }
    
    public struct tokenURIResponse: ABIResponse {
        public static var types: [ABIType.Type] = [ URL.self ]
        public let uri: URL
        
        public init?(values: [ABIType]) throws {
            self.uri = try values[0].decoded()
        }
    }
}

public enum ERC721EnumerableResponses {
    public struct numberResponse: ABIResponse {
        public static var types: [ABIType.Type] = [ BigUInt.self ]
        public let value: BigUInt
        
        public init?(values: [ABIType]) throws {
            self.value = try values[0].decoded()
        }
    }
}
