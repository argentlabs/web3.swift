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
    init(to: String, value: Ether?, data: Data?, nonce: Int?, gasPrice: Ether?, gasLimit: BigUInt?, chainId: Int?)
    init(to: String, data: Data, chainId: Int?)
    
    init(to: String, value: Ether?, data: Data?, nonce: Int?, gasPrice: Ether?, gasLimit: BigUInt?)
    init(to: String, data: Data)
    
    var raw: Data? { get }
    var hash: Data? { get }
}

public struct EthereumTransaction: EthereumTransactionProtocol, Codable {
    public let to: String
    public let value: Ether?
    public let data: Data?
    public var nonce: Int?
    public let gasPrice: Ether?
    public let gasLimit: BigUInt?
    var chainId: Int?
        
    init(to: String, value: Ether?, data: Data?, nonce: Int?, gasPrice: Ether?, gasLimit: BigUInt?, chainId: Int?) {
        self.to = to
        self.value = value
        self.data = data ?? Data()
        self.nonce = nonce
        self.gasPrice = gasPrice
        self.gasLimit = gasLimit
        self.chainId = chainId
    }
    
    public init(to: String, value: Ether?, data: Data?, nonce: Int?, gasPrice: Ether?, gasLimit: BigUInt?) {
        self.to = to
        self.value = value
        self.data = data ?? Data()
        self.nonce = nonce
        self.gasPrice = gasPrice
        self.gasLimit = gasLimit
    }
    
    init(to: String, data: Data, chainId: Int?) {
        self.init(to: to, value: nil, data: data, nonce: nil, gasPrice: nil, gasLimit: nil, chainId: chainId)
    }
    
    public init(to: String, data: Data) {
        self.init(to: to, value: nil, data: data, nonce: nil, gasPrice: nil, gasLimit: nil)
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
