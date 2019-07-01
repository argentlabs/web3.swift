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
        
        init?(values: [ABIType]) throws {
            self.value = try values[0].decoded()
        }
    }
    
    struct ownerResponse: ABIResponse {
        static var types: [ABIType.Type] = [ EthereumAddress.self ]
        let value: EthereumAddress
        
        init?(values: [ABIType]) throws {
            self.value = try values[0].decoded()
        }
    }
}

public enum ERC721MetadataResponses {
    struct nameResponse: ABIResponse {
        static var types: [ABIType.Type] = [ String.self ]
        let value: String
        
        init?(values: [ABIType]) throws {
            self.value = try values[0].decoded()
        }
    }
    
    struct symbolResponse: ABIResponse {
        static var types: [ABIType.Type] = [ String.self ]
        let value: String
        
        init?(values: [ABIType]) throws {
            self.value = try values[0].decoded()
        }
    }
    
    struct tokenURIResponse: ABIResponse {
        static var types: [ABIType.Type] = [ URL.self ]
        let uri: URL
        
        init?(values: [ABIType]) throws {
            self.uri = try values[0].decoded()
        }
    }
}

public enum ERC721EnumerableResponses {
    struct numberResponse: ABIResponse {
        static var types: [ABIType.Type] = [ BigUInt.self ]
        let value: BigUInt
        
        init?(values: [ABIType]) throws {
            self.value = try values[0].decoded()
        }
    }
}
