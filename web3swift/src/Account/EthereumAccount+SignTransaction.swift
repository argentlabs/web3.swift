//
//  EthereumAccount+Sign.swift
//  web3swift
//
//  Created by Matt Marshall on 09/03/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation

enum EthereumSignerError: Error {
    case emptyRawTransaction
    case unknownError
}

public extension EthereumAccount {
    
    func signRaw(_ transaction: EthereumTransaction) throws -> Data {
        let signed: SignedTransaction = try sign(transaction: transaction)
        guard let raw = signed.raw else {
            throw EthereumSignerError.unknownError
        }
        return raw
    }
    
    func sign(transaction: EthereumTransaction) throws -> SignedTransaction {
        
        guard let raw = transaction.raw else {
            throw EthereumSignerError.emptyRawTransaction
        }
        
        guard let signature = try? self.sign(data: raw) else {
            throw EthereumSignerError.unknownError
        }
        
        let r = signature.subdata(in: 0..<32)
        let s = signature.subdata(in: 32..<64)
        
        var v = Int(signature[64])
        if v < 37 {
            v += (transaction.chainId ?? -1) * 2 + 35
        }
        
        return SignedTransaction(transaction: transaction, v: v, r: r, s: s)
    }
}
