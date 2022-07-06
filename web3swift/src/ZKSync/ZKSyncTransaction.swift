//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation
import BigInt
import GenericJSON

// to be filled in by client
public struct ZKSyncTransaction: Equatable {
    public static let eip712Type: UInt8 = 0x71
    
    public let txType: UInt8 = Self.eip712Type
    public var to: EthereumAddress
    public var value: BigUInt
    public var data: Data
    public var chainId: Int?
    public var nonce: Int?
    public var gasPrice: BigUInt?
    public var gasLimit: BigUInt?
    public var egsPerPubdata: BigUInt
    public var feeToken: EthereumAddress
    public var aaParams: AAParams?
    
    public init(
        to: EthereumAddress,
        value: BigUInt,
        data: Data,
        chainId: Int? = nil,
        nonce: Int? = nil,
        gasPrice: BigUInt? = nil,
        gasLimit: BigUInt? = nil,
        egsPerPubdata: BigUInt = 0,
        feeToken: EthereumAddress = .zero,
        aaParams: AAParams? = nil
    ) {
        self.to = to
        self.value = value
        self.data = data
        self.chainId = chainId
        self.nonce = nonce
        self.gasPrice = gasPrice
        self.gasLimit = gasLimit
        self.egsPerPubdata = egsPerPubdata
        self.feeToken = feeToken
        self.aaParams = aaParams
    }
    
    public struct AAParams: Equatable {
        public var from: EthereumAddress
        
        public init(
            from: EthereumAddress
        ) {
            self.from = from
        }
    }
    
    public var eip712Representation: TypedData {
        let decoder = JSONDecoder()
        let eip712 = try! decoder.decode(TypedData.self, from: eip712JSON)
        return eip712
    }
    
    private var eip712JSON: Data {
        """
        {
            "types": {
                "EIP712Domain": [
                  {"name": "name", "type": "string"},
                  {"name": "version", "type": "string"},
                  {"name": "chainId", "type": "uint256"}
                ],
                "Transaction": [
                    {"name": "txType","type": "uint8"},
                    {"name": "to","type": "uint256"},
                    {"name": "value","type": "uint256"},
                    {"name": "data","type": "bytes"},
                    {"name": "feeToken","type": "uint256"},
                    {"name": "ergsLimit","type": "uint256"},
                    {"name": "ergsPerPubdataByteLimit","type": "uint256"},
                    {"name": "ergsPrice","type": "uint256"},
                    {"name": "nonce","type": "uint256"}
                ]
            },
            "primaryType": "Transaction",
            "domain": {
                "name": "zkSync",
                "version": "2",
                "chainId": \(chainId!)
            },
            "message": {
                "txType" : \(txType),
                "to" : "\(to.asBigInt.web3.hexString)",
                "value" : "\(value.web3.hexString)",
                "data" : "\(data.web3.hexString)",
                "feeToken" : "\(feeToken.asBigInt.web3.hexString)",
                "ergsLimit" : "\(gasLimit!.web3.hexString)",
                "ergsPrice" : "\(gasPrice!.web3.hexString)",
                "ergsPerPubdataByteLimit" : \(egsPerPubdata.description),
                "nonce" : \(nonce!)
            }
        }
        """.data(using: .utf8)!
    }
}

public struct ZKSyncSignedTransaction {
    public enum SignatureParam {
        case eoa(Signature)
        case aa(signature: Signature, from: EthereumAddress)
        
        public var signature: Signature {
            switch self {
            case .aa(let signature, _):
                return signature
            case .eoa(let signature):
                return signature
            }
        }
    }
    
    public let transaction: ZKSyncTransaction
    public let sigParam: SignatureParam
    
    public init(
        transaction: ZKSyncTransaction,
        sigParam: SignatureParam
    ) {
        self.transaction = transaction
        self.sigParam = sigParam
    }
    
    public var raw: Data? {
        guard transaction.nonce != nil, transaction.chainId != nil,
              transaction.gasPrice != nil, transaction.gasLimit != nil else {
            return nil
        }
        
        var txArray: [Any?] = [
            transaction.nonce,
            transaction.gasPrice,
            transaction.gasLimit,
            transaction.to.value.web3.noHexPrefix,
            transaction.value,
            transaction.data
        ]
        
        switch sigParam {
        case .eoa(let signature):
            txArray.append(signature.recoveryParam)
            txArray.append(signature.r)
            txArray.append(signature.s)
        case .aa:
            txArray.append(transaction.chainId)
            txArray.append(Data())
            txArray.append(Data())
        }
        
        txArray.append(transaction.chainId)
        txArray.append(transaction.feeToken.value.web3.noHexPrefix)
        txArray.append(transaction.egsPerPubdata)
        // TODO factorydeps
        txArray.append([])
        
        switch sigParam {
        case .eoa:
            txArray.append([])
        case .aa(let signature, let from):
            txArray.append(
                [
                    from.value.web3.noHexPrefix,
                    signature.raw
                ]
            )
        }

        return RLP.encode(txArray).flatMap {
            Data([transaction.txType]) + $0.web3.bytes
        }
    }
    
    public var hash: Data? {
        return raw?.web3.keccak256
    }
    
    private var signature: Signature {
        sigParam.signature
    }
}

fileprivate extension EthereumAddress {
    var asBigInt: BigUInt {
        .init(hex: self.value)!
    }
}


extension ABIFunction {
    public func zkTransaction(
        from: EthereumAddress? = nil,
        value: BigUInt? = nil,
        gasPrice: BigUInt? = nil,
        gasLimit: BigUInt? = nil,
        ergsPerPubData: BigUInt = 0, // TODO,
        feeToken: EthereumAddress = .zero
    ) throws -> ZKSyncTransaction {
        let encoder = ABIFunctionEncoder(Self.name)
        try self.encode(to: encoder)
        let data = try encoder.encoded()

        return ZKSyncTransaction(
            to: contract,
            value: value ?? 0,
            data: data,
            gasPrice: self.gasPrice ?? gasPrice ?? 0,
            gasLimit: self.gasLimit ?? gasLimit ?? 0,
            egsPerPubdata: ergsPerPubData,
            feeToken: feeToken,
            aaParams: from.map(ZKSyncTransaction.AAParams.init)
        )
    }
}
