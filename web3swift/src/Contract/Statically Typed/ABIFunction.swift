//
//  ABIFunction.swift
//  web3swift
//
//  Created by Matt Marshall on 09/04/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation
import BigInt

public protocol ABIFunction {
    static var name: String { get }
    var gasPrice: BigUInt? { get }
    var gasLimit: BigUInt? { get }
    var contract: EthereumAddress { get }
    var from: EthereumAddress? { get }
    func encode(to encoder: ABIFunctionEncoder) throws
    func transaction() throws -> EthereumTransaction
}

public protocol ABIResponse: ABITupleDecodable {}

extension ABIFunction {
    public func transaction() throws -> EthereumTransaction {
        let encoder = ABIFunctionEncoder(Self.name)
        try self.encode(to: encoder)
        let data = try encoder.encoded()
        
        return EthereumTransaction(from: from, to: contract, data: data, gasPrice: gasPrice ?? BigUInt(0), gasLimit: gasLimit ?? BigUInt(0))
    }
}
