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
    struct balanceResponse: ABIResponse {
        static var types: [ABIType.Type] = [ BigUInt.self ]
        let value: BigUInt
        
        init?(values: [String]) throws {
            self.value = try ABIDecoder.decode(values[0], to: BigUInt.self)
        }
    }
    
    struct ownerResponse: ABIResponse {
        static var types: [ABIType.Type] = [ EthereumAddress.self ]
        let value: EthereumAddress
        
        init?(values: [String]) throws {
            self.value = try ABIDecoder.decode(values[0], to: EthereumAddress.self)
        }
    }
}

public enum ERC721MetadataResponses {
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
    
    struct tokenURIResponse: ABIResponse {
        static var types: [ABIType.Type] = [ URL.self ]
        let uri: URL
        
        init?(values: [String]) throws {
            self.uri = try ABIDecoder.decode(values[0], to: URL.self)
        }
    }
}

public enum ERC721EnumerableResponses {
    struct numberResponse: ABIResponse {
        static var types: [ABIType.Type] = [ BigUInt.self ]
        let value: BigUInt
        
        init?(values: [String]) throws {
            self.value = try ABIDecoder.decode(values[0], to: BigUInt.self)
        }
    }
}
