//
//  EthereumTransaction.swift
//  web3swift
//
//  Created by Julien Niset on 23/02/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation
import BigInt

protocol EthereumTransactionProtocol {
    init(from: String?, to: String, value: BigUInt?, data: Data?, nonce: Int?, gasPrice: BigUInt?, gasLimit: BigUInt?, chainId: Int?)
    init(from: String?, to: String, data: Data, gasPrice: BigUInt, gasLimit: BigUInt)
    init(to: String, data: Data)
    
    var raw: Data? { get }
    var hash: Data? { get }
}

public struct EthereumTransaction: EthereumTransactionProtocol, Codable {
    public let from: String?
    public let to: String
    public let value: BigUInt?
    public let data: Data?
    public var nonce: Int?
    public let gasPrice: BigUInt?
    public let gasLimit: BigUInt?
    var chainId: Int?
    
    public init(from: String?, to: String, value: BigUInt?, data: Data?, nonce: Int?, gasPrice: BigUInt?, gasLimit: BigUInt?, chainId: Int?) {
        self.from = from
        self.to = to
        self.value = value
        self.data = data ?? Data()
        self.nonce = nonce
        self.gasPrice = gasPrice
        self.gasLimit = gasLimit
        self.chainId = chainId
    }
    
    public init(from: String?, to: String, data: Data, gasPrice: BigUInt, gasLimit: BigUInt) {
        self.from = from
        self.to = to
        self.value = BigUInt(0)
        self.data = data
        self.gasPrice = gasPrice
        self.gasLimit = gasLimit
    }
    
    public init(to: String, data: Data) {
        self.from = nil
        self.to = to
        self.value = BigUInt(0)
        self.data = data
        self.gasPrice = BigUInt(0)
        self.gasLimit = BigUInt(0)
    }
    
    var raw: Data? {
        let txArray: [Any?] = [self.nonce, self.gasPrice, self.gasLimit, self.to.noHexPrefix, self.value, self.data, self.chainId, 0, 0]

        return RLP.encode(txArray)
    }
    
    var hash: Data? {
        return raw?.keccak256
    }
}

struct SignedTransaction {
    let transaction: EthereumTransaction
    let v: Int
    let r: Data
    let s: Data
    
    init(transaction: EthereumTransaction, v: Int, r: Data, s: Data) {
        self.transaction = transaction
        self.v = v
        self.r = r.strippingZeroesFromBytes
        self.s = s.strippingZeroesFromBytes
    }
    
    var raw: Data? {
        let txArray: [Any?] = [transaction.nonce, transaction.gasPrice, transaction.gasLimit, transaction.to.noHexPrefix, transaction.value, transaction.data, self.v, self.r, self.s]

        return RLP.encode(txArray)
    }
    
    var hash: Data? {
        return raw?.keccak256
    }
}
