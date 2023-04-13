//
//  web3.swift
//  Copyright © 2023 Argent Labs Limited. All rights reserved.
//

import web3
import BigInt
import Foundation

extension ABIFunction {
    public func zkSyncTransaction(
        value: BigUInt? = nil,
        gasPrice: BigUInt? = nil,
        gasLimit: BigUInt? = nil,
        chainId: Int? = nil,
        nonce: Int? = nil
    ) throws -> ZKSyncTransaction {
        guard let from = from else {
            throw ABIError.invalidValue
        }

        let encoder = ABIFunctionEncoder(Self.name)
        try encode(to: encoder)
        let data = try encoder.encoded()

        return ZKSyncTransaction(
            from: from,
            to: contract,
            value: value ?? 0,
            data: data,
            chainId: chainId,
            nonce: nonce,
            gasPrice: self.gasPrice ?? gasPrice ?? 0,
            gasLimit: self.gasLimit ?? gasLimit ?? 0
        )
    }
}
