//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation
import BigInt

public protocol EthereumTransactionProtocol {
    init(from: EthereumAddress?, to: EthereumAddress, value: BigUInt?, data: Data?, nonce: Int?, gasPrice: BigUInt?, gasLimit: BigUInt?, chainId: Int?)
    init(from: EthereumAddress?, to: EthereumAddress, data: Data, gasPrice: BigUInt, gasLimit: BigUInt)
    init(to: EthereumAddress, data: Data)
    
    var raw: Data? { get }
    var hash: Data? { get }
}

public struct EthereumTransaction: EthereumTransactionProtocol, Equatable, Codable {
    public let from: EthereumAddress?
    public let to: EthereumAddress
    public let value: BigUInt?
    public let data: Data?
    public var nonce: Int?
    public let gasPrice: BigUInt?
    public let gasLimit: BigUInt?
    public let gas: BigUInt?
    public let blockNumber: EthereumBlock?
    public private(set) var hash: Data?
    public var chainId: Int? {
        didSet {
            self.hash = self.raw?.web3.keccak256
        }
    }
    
    public init(from: EthereumAddress?, to: EthereumAddress, value: BigUInt?, data: Data?, nonce: Int?, gasPrice: BigUInt?, gasLimit: BigUInt?, chainId: Int?) {
        self.from = from
        self.to = to
        self.value = value
        self.data = data ?? Data()
        self.nonce = nonce
        self.gasPrice = gasPrice
        self.gasLimit = gasLimit
        self.chainId = chainId
        self.gas = nil
        self.blockNumber = nil
        let txArray: [Any?] = [self.nonce, self.gasPrice, self.gasLimit, self.to, self.value, self.data, self.chainId, 0, 0]
        self.hash = RLP.encode(txArray)
    }

    public init(
        from: EthereumAddress?,
        to: EthereumAddress,
        data: Data,
        gasPrice: BigUInt,
        gasLimit: BigUInt
    ) {
        self.init(
            from: from,
            to: to,
            value: 0,
            data: data,
            gasPrice: gasPrice,
            gasLimit: gasLimit
        )
    }
    
    public init(
        from: EthereumAddress?,
        to: EthereumAddress,
        value: BigUInt = 0,
        data: Data,
        gasPrice: BigUInt,
        gasLimit: BigUInt
    ) {
        self.from = from
        self.to = to
        self.value = value
        self.data = data
        self.gasPrice = gasPrice
        self.gasLimit = gasLimit
        self.gas = nil
        self.blockNumber = nil
        self.hash = nil
    }
    
    public init(to: EthereumAddress, data: Data) {
        self.from = nil
        self.to = to
        self.value = BigUInt(0)
        self.data = data
        self.gasPrice = BigUInt(0)
        self.gasLimit = BigUInt(0)
        self.gas = nil
        self.blockNumber = nil
        self.hash = nil
    }
    
    public var raw: Data? {
        let txArray: [Any?] = [nonce, gasPrice, gasLimit, to, value, data, chainId, 0, 0]

        return RLP.encode(txArray)
    }
    
    enum CodingKeys : String, CodingKey {
        case from
        case to
        case value
        case data
        case nonce
        case gasPrice
        case gas
        case gasLimit
        case blockNumber
        case hash
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.to = try container.decode(EthereumAddress.self, forKey: .to)
        self.from = try? container.decode(EthereumAddress.self, forKey: .from)
        self.data = try? container.decode(Data.self, forKey: .data)
        
        let decodeHexUInt = { (key: CodingKeys) -> BigUInt? in
            return (try? container.decode(String.self, forKey: key)).flatMap { BigUInt(hex: $0)}
        }
        
        let decodeHexInt = { (key: CodingKeys) -> Int? in
            return (try? container.decode(String.self, forKey: key)).flatMap { Int(hex: $0)}
        }
        
        self.value = decodeHexUInt(.value)
        self.gasLimit = decodeHexUInt(.gasLimit)
        self.gasPrice = decodeHexUInt(.gasPrice)
        self.gas = decodeHexUInt(.gas)
        self.nonce = decodeHexInt(.nonce)
        self.blockNumber = try? container.decode(EthereumBlock.self, forKey: .blockNumber)
        self.hash = (try? container.decode(String.self, forKey: .hash))?.web3.hexData
        self.chainId = nil
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(to, forKey: .to)
        try? container.encode(from, forKey: .from)
        try? container.encode(data, forKey: .data)
        try? container.encode(value?.web3.hexString, forKey: .value)
        try? container.encode(gasPrice?.web3.hexString, forKey: .gasPrice)
        try? container.encode(gasLimit?.web3.hexString, forKey: .gasLimit)
        try? container.encode(gas?.web3.hexString, forKey: .gas)
        try? container.encode(nonce?.web3.hexString, forKey: .nonce)
        try? container.encode(blockNumber, forKey: .blockNumber)
        try? container.encode(hash?.web3.hexString, forKey: .hash)
    }
}

public struct SignedTransaction {
    public let transaction: EthereumTransaction
    public let signature: Signature
    
    public init(
        transaction: EthereumTransaction,
        signature raw: Data
    ) {
        self.transaction = transaction
        self.signature = .init(raw: raw)
    }
    
    var r: Data {
        signature.r
    }
    
    var s: Data {
        signature.s
    }
    
    var v: Int {
        guard signature.v < 37 else {
            return signature.v
        }
        return signature.v + (transaction.chainId ?? -1) * 2 + 8
    }
    
    public var raw: Data? {
        let txArray: [Any?] = [transaction.nonce, transaction.gasPrice, transaction.gasLimit, transaction.to, transaction.value, transaction.data, v, r, s]

        return RLP.encode(txArray)
    }
    
    public var hash: Data? {
        return raw?.web3.keccak256
    }
}
