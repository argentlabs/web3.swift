//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation

enum EthereumSignerError: Error {
    case emptyRawTransaction
    case unknownError
}

public extension EthereumAccount {
    func signRaw(_ transaction: EthereumTransaction) async throws -> Data {
        let signed: SignedTransaction = try await sign(transaction: transaction)
        guard let raw = signed.raw else {
            throw EthereumSignerError.unknownError
        }
        return raw
    }

    func sign(transaction: EthereumTransaction) async throws -> SignedTransaction {
        guard let raw = transaction.raw else {
            throw EthereumSignerError.emptyRawTransaction
        }

        guard let signature = try? await sign(data: raw) else {
            throw EthereumSignerError.unknownError
        }

        let r = signature.subdata(in: 0 ..< 32)
        let s = signature.subdata(in: 32 ..< 64)

        var v = Int(signature[64])
        if v < 37 {
            v += (transaction.chainId ?? -1) * 2 + 35
        }

        return SignedTransaction(transaction: transaction, v: v, r: r, s: s)
    }
}
