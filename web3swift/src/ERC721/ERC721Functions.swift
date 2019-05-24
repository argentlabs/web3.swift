//
//  ERC721Functions.swift
//  web3swift
//
//  Created by Miguel on 09/05/2019.
//  Copyright © 2019 Argent Labs Limited. All rights reserved.
//

import Foundation
import BigInt

public enum ERC721Functions {
    static var interfaceID: Data {
        return "0x80ac58cd".hexData!
    }
    
    struct balanceOf: ABIFunction {
        static let name = "balanceOf"
        let gasPrice: BigUInt? = nil
        let gasLimit: BigUInt? = nil
        var contract: EthereumAddress
        let from: EthereumAddress? = nil
        let owner: EthereumAddress
        
        func encode(to encoder: ABIFunctionEncoder) throws {
            try encoder.encode(owner)
        }
    }
    
    struct ownerOf: ABIFunction {
        static let name = "ownerOf"
        let gasPrice: BigUInt? = nil
        let gasLimit: BigUInt? = nil
        var contract: EthereumAddress
        let from: EthereumAddress? = nil
        let tokenId: BigUInt
        
        func encode(to encoder: ABIFunctionEncoder) throws {
            try encoder.encode(tokenId)
        }
    }
}

public enum ERC721MetadataFunctions {
    static var interfaceID: Data {
        return "name()".keccak256.bytes4 ^
            "symbol()".keccak256.bytes4 ^
            "tokenURI(uint256)".keccak256.bytes4
    }
    
    struct name: ABIFunction {
        static let name = "name"
        let gasPrice: BigUInt? = nil
        let gasLimit: BigUInt? = nil
        var contract: EthereumAddress
        let from: EthereumAddress? = nil
        
        func encode(to encoder: ABIFunctionEncoder) throws { }
    }
    
    struct symbol: ABIFunction {
        static let name = "symbol"
        let gasPrice: BigUInt? = nil
        let gasLimit: BigUInt? = nil
        var contract: EthereumAddress
        let from: EthereumAddress? = nil
        
        func encode(to encoder: ABIFunctionEncoder) throws { }
    }
 
    struct tokenURI: ABIFunction {
        static let name = "tokenURI"
        let gasPrice: BigUInt? = nil
        let gasLimit: BigUInt? = nil
        var contract: EthereumAddress
        let from: EthereumAddress? = nil
        
        let tokenID: BigUInt
        
        func encode(to encoder: ABIFunctionEncoder) throws {
            try encoder.encode(tokenID)
        }
    }
}

public enum ERC721EnumerableFunctions {
    static var interfaceID: Data {
        return "totalSupply()".keccak256.bytes4 ^
            "tokenByIndex(uint256)".keccak256.bytes4 ^
            "tokenOfOwnerByIndex(address,uint256)".keccak256.bytes4
    }

    struct totalSupply: ABIFunction {
        static let name = "totalSupply"
        let gasPrice: BigUInt? = nil
        let gasLimit: BigUInt? = nil
        var contract: EthereumAddress
        let from: EthereumAddress? = nil
        
        func encode(to encoder: ABIFunctionEncoder) throws { }
    }
    
    struct tokenByIndex: ABIFunction {
        static let name = "tokenByIndex"
        let gasPrice: BigUInt? = nil
        let gasLimit: BigUInt? = nil
        var contract: EthereumAddress
        let from: EthereumAddress? = nil
        
        let index: BigUInt
        
        func encode(to encoder: ABIFunctionEncoder) throws {
            try encoder.encode(index)
        }
    }
    
    struct tokenOfOwnerByIndex: ABIFunction {
        static let name = "tokenOfOwnerByIndex"
        let gasPrice: BigUInt? = nil
        let gasLimit: BigUInt? = nil
        var contract: EthereumAddress
        let from: EthereumAddress? = nil
        
        let address: EthereumAddress
        let index: BigUInt
        
        func encode(to encoder: ABIFunctionEncoder) throws {
            try encoder.encode(address)
            try encoder.encode(index)
        }
    }
}
