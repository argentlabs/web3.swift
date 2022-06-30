//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation
import BigInt

public protocol ZKSyncEthereumClient {
    func eth_sendRawZKSyncTransaction(_ transaction: ZKSyncTransaction, withAccount account: EthereumAccountProtocol) async throws -> String
    func gasPrice() async throws -> BigUInt
    func estimateGas(_ transaction: ZKSyncTransaction) async throws -> BigUInt
}

extension EthereumClientProtocol {
    public func eth_sendRawZKSyncTransaction(_ transaction: ZKSyncTransaction, withAccount account: EthereumAccountProtocol) async throws -> String {
        // Inject pending nonce
        let nonce = try await self.eth_getTransactionCount(address: account.address, block: .Pending)

        var transaction = transaction
        transaction.nonce = nonce

        if transaction.chainId == nil, let network = self.network {
            transaction.chainId = network.intValue
        }

        guard let signedTx = try? account.sign(zkTransaction: transaction),
              let transactionHex = signedTx.raw?.web3.hexString else {
            throw EthereumClientError.encodeIssue
        }

        fatalError("MIQU")

//        let txHash = try await networkProvider.send(
//            method: "eth_sendRawTransaction",
//            params: [transactionHex],
//            receive: String.self
//        )
//            if let resDataString = response as? String {
//                completionHandler(.success(resDataString))
//            } else {
//
//                if case let .executionError(result) = error as? JSONRPCError {
//                    completionHandler(.failure(.executionError(result.error)))
//                } else {
//                    completionHandler(.failure(.unexpectedReturnValue))
//                }
//            }
//        }
    }
    
    public func gasPrice() async throws -> BigUInt {
        try await eth_gasPrice()
    }

    func estimateGas(_ transaction: ZKSyncTransaction) async throws -> BigUInt {

        fatalError("MIQU")
//        let value = transaction.value > .zero ? transaction.value : nil
//        let params = EstimateGasParams(from: transaction.from.value,
//                                to: transaction.to.value,
//                                gas: transaction.gasLimit?.web3.hexString,
//                                gasPrice: transaction.gasPrice?.web3.hexString,
//                                value: value?.web3.hexString,
//                                data: transaction.data.web3.hexString)
//        EthereumRPC.execute(session: session, url: url, method: "eth_estimateGas", params: params, receive: String.self) { (error, response) in
//            if let gasHex = response as? String, let gas = BigUInt(hex: gasHex) {
//                completion(nil, gas)
//            } else if case let .executionError(result) = error as? JSONRPCError {
//                completion(.executionError(result.error), nil)
//            } else {
//                completion(.unexpectedReturnValue, nil)
//            }
//        }
    }
}
