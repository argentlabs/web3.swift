//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import BigInt
import Foundation

public protocol ABIFunction: ABIFunctionEncodable {
    var gasPrice: BigUInt? { get }
    var gasLimit: BigUInt? { get }
    var contract: EthereumAddress { get }
    var from: EthereumAddress? { get }
}

public protocol ABIResponse: ABITupleDecodable {}

extension ABIFunction {
    public func transaction(
        value: BigUInt? = nil,
        gasPrice: BigUInt? = nil,
        gasLimit: BigUInt? = nil
    ) throws -> EthereumTransaction {
        let encoder = ABIFunctionEncoder(Self.name)
        try encode(to: encoder)
        let data = try encoder.encoded()

        return EthereumTransaction(
            from: from,
            to: contract,
            value: value ?? 0,
            data: data,
            gasPrice: self.gasPrice ?? gasPrice ?? 0,
            gasLimit: self.gasLimit ?? gasLimit ?? 0
        )
    }
}
