//
//  ERC1271Functions.swift
//  
//
//  Created by Rodrigo Kreutz on 15/06/22.
//

import Foundation
import BigInt

public enum ERC1271Functions {

    public struct isValidSignature: ABIFunction {
        
        public static let name = "isValidSignature"
        public let gasPrice: BigUInt? = nil
        public let gasLimit: BigUInt? = nil
        public let from: EthereumAddress? = nil
        public var contract: EthereumAddress

        public let message: Data
        public let signature: Data

        public init(contract: EthereumAddress,
                    message: Data,
                    signature: Data) throws {
            guard message.count == 32 && signature.count == 65 else { throw ERC1271Error.invalidInput }
            self.contract = contract
            self.message = message
            self.signature = signature
        }

        public func encode(to encoder: ABIFunctionEncoder) throws {
            try encoder.encode(message, staticSize: 32)
            try encoder.encode(signature)
        }
    }
}
