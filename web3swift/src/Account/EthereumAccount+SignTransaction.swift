//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation

enum EthereumSignerError: Error {
    case emptyRawTransaction
    case unknownError
}

public extension EthereumAccountProtocol {
    
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
        
        return SignedTransaction(transaction: transaction, signature: signature)
    }
}
