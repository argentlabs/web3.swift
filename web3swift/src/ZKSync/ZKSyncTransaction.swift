//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import web3
import BigInt
import Foundation
import GenericJSON

// to be filled in by client
public struct ZKSyncTransaction: Equatable {
    public static let eip712Type: UInt8 = 0x71
    public static let gasPerPubDataByte: BigUInt = 16
    public static let defaultErgsPerPubDataLimit: BigUInt = gasPerPubDataByte * 10_000

    public let txType: UInt8 = Self.eip712Type
    public var from: EthereumAddress
    public var to: EthereumAddress
    public var value: BigUInt
    public var data: Data
    public var chainId: Int?
    public var nonce: Int?
    public var gasPrice: BigUInt?
    public var gasLimit: BigUInt?
    public var ergsPerPubdata: BigUInt
    public var maxFeePerGas: BigUInt?
    public var maxPriorityFeePerGas: BigUInt?
    public var paymasterParams: PaymasterParams

    public init(
        from: EthereumAddress,
        to: EthereumAddress,
        value: BigUInt,
        data: Data,
        chainId: Int? = nil,
        nonce: Int? = nil,
        gasPrice: BigUInt? = nil,
        gasLimit: BigUInt? = nil,
        ergsPerPubData: BigUInt = ZKSyncTransaction.defaultErgsPerPubDataLimit,
        maxFeePerGas: BigUInt? = nil,
        maxPriorityFeePerGas: BigUInt? = nil,
        paymasterParams: PaymasterParams = .none
    ) {
        self.from = from
        self.to = to
        self.value = value
        self.data = data
        self.chainId = chainId
        self.nonce = nonce
        self.gasPrice = gasPrice
        self.gasLimit = gasLimit
        self.ergsPerPubdata = ergsPerPubData
        self.maxFeePerGas = maxFeePerGas
        self.maxPriorityFeePerGas = maxPriorityFeePerGas
        self.paymasterParams = paymasterParams
    }

    public struct PaymasterParams: Equatable {
        public var paymaster: EthereumAddress
        public var input: Data
        public init(
            paymaster: EthereumAddress,
            input: Data
        ) {
            self.paymaster = paymaster
            self.input = input
        }

        public var isEmpty: Bool {
            self.paymaster == .zero
        }

        public static let none: PaymasterParams = .init(paymaster: .zero, input: Data())
    }

    public var maxFeePerErg: BigUInt {
        maxFeePerGas ?? gasPrice ?? 0
    }

    public var maxPriorityFeePerErg: BigUInt {
        maxPriorityFeePerGas ?? maxFeePerErg
    }

    var paymaster: EthereumAddress {
        paymasterParams.paymaster
    }

    var paymasterInput: Data {
        paymasterParams.input
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
                    {"name": "txType","type": "uint256"},
                    {"name": "from","type": "uint256"},
                    {"name": "to","type": "uint256"},
                    {"name": "ergsLimit","type": "uint256"},
                    {"name": "ergsPerPubdataByteLimit","type": "uint256"},
                    {"name": "maxFeePerErg", "type": "uint256"},
                    {"name": "maxPriorityFeePerErg", "type": "uint256"},
                    {"name": "paymaster", "type": "uint256"},
                    {"name": "nonce","type": "uint256"},
                    {"name": "value","type": "uint256"},
                    {"name": "data","type": "bytes"},
                    {"name": "factoryDeps","type": "bytes32[]"},
                    {"name": "paymasterInput", "type": "bytes"}
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
                "from" : "\(from.asBigInt.description)",
                "to" : "\(to.asBigInt.description)",
                "ergsLimit" : "\(gasLimit!.description)",
                "ergsPerPubdataByteLimit" : "\(ergsPerPubdata.description)",
                "maxFeePerErg" : "\(maxFeePerErg.description)",
                "maxPriorityFeePerErg" : "\(maxPriorityFeePerErg.description)",
                "paymaster" : "\(paymaster.asBigInt.description)",
                "nonce" : \(nonce!),
                "value" : "\(value.description)",
                "data" : "\(data.web3.hexString)",
                "factoryDeps" : [],
                "paymasterInput" : "\(paymasterInput.web3.hexString)"
            }
        }
        """.data(using: .utf8)!
    }
}

public struct ZKSyncSignedTransaction {
    public let transaction: ZKSyncTransaction
    public let signature: Signature

    public init(
        transaction: ZKSyncTransaction,
        signature: Signature
    ) {
        self.transaction = transaction
        self.signature = signature
    }

    public var raw: Data? {
        guard transaction.nonce != nil, transaction.chainId != nil,
              transaction.gasPrice != nil, transaction.gasLimit != nil else {
            return nil
        }

        var txArray: [Any?] = [
            transaction.nonce,
            transaction.maxPriorityFeePerErg,
            transaction.maxFeePerErg,
            transaction.gasLimit,
            transaction.to.value,
            transaction.value,
            transaction.data
        ]

        txArray.append(transaction.chainId)
        txArray.append(Data())
        txArray.append(Data())

        txArray.append(transaction.chainId)
        txArray.append(transaction.from.value)

        txArray.append(transaction.ergsPerPubdata)
        // TODO: factorydeps
        txArray.append([])

        txArray.append(signature.flattened)

        if transaction.paymasterParams.isEmpty {
            txArray.append([])
        } else {
            txArray.append([
                transaction.paymaster,
                transaction.paymasterInput
            ])
        }

        return RLP.encode(txArray).flatMap {
            Data([transaction.txType]) + $0.web3.bytes
        }
    }

    public var hash: Data? {
        raw?.web3.keccak256
    }
}

fileprivate extension EthereumAddress {
    var asBigInt: BigUInt {
        .init(hex: self.value)!
    }
}

extension ABIFunction {
    public func zkTransaction(
        from: EthereumAddress,
        value: BigUInt? = nil,
        gasPrice: BigUInt? = nil,
        gasLimit: BigUInt? = nil,
        feeToken: EthereumAddress = .zero
    ) throws -> ZKSyncTransaction {
        let encoder = ABIFunctionEncoder(Self.name)
        try self.encode(to: encoder)
        let data = try encoder.encoded()

        return ZKSyncTransaction(
            from: from,
            to: contract,
            value: value ?? 0,
            data: data,
            gasPrice: self.gasPrice ?? gasPrice ?? 0,
            gasLimit: self.gasLimit ?? gasLimit ?? 0
        )
    }
}
