//
//  ERC165.swift
//  web3swift
//
//  Created by Miguel on 09/05/2019.
//  Copyright © 2019 Argent Labs Limited. All rights reserved.
//

import Foundation
import BigInt

public class ERC165 {
    let client: EthereumClient
    public init(client: EthereumClient) {
        self.client = client
    }
    
    public func supportsInterface(contract: EthereumAddress,
                                  id: Data,
                                  completion: @escaping((Error?, Bool?) -> Void)) {
        let function = ERC165Functions.supportsInterface(contract: contract, interfaceId: id)
        function.call(withClient: self.client,
                      responseType: ERC165Responses.supportsInterfaceResponse.self) { (error, response) in
            return completion(error, response?.supported)
        }
    }

}

public enum ERC165Functions {
    public static var interfaceId: Data {
        return "supportsInterface(bytes4)".keccak256.bytes4
    }
    
    struct supportsInterface: ABIFunction {
        static let name = "supportsInterface"
        let gasPrice: BigUInt? = nil
        let gasLimit: BigUInt? = nil
        var contract: EthereumAddress
        let from: EthereumAddress? = nil
        
        let interfaceId: Data
        
        func encode(to encoder: ABIFunctionEncoder) throws {
            assert(interfaceId.count == 4, "Interface data should contain exactly 4 bytes")
            try encoder.encode(interfaceId, size: Data4.self)
        }
    }
}

public enum ERC165Responses {
    struct supportsInterfaceResponse: ABIResponse {
        static var types: [ABIType.Type] = [ Bool.self ]
        let supported: Bool
        
        init?(values: [String]) throws {
            self.supported = try ABIDecoder.decode(values[0], to: Bool.self)
        }
    }
}
