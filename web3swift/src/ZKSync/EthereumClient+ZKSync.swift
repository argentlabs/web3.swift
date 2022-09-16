//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation
import BigInt

public protocol ZKSyncEthereumClient {
    func eth_sendRawZKSyncTransaction(_ transaction: ZKSyncTransaction, withAccount account: EthereumAccountProtocol, completionHandler: @escaping (Result<String, EthereumClientError>) -> Void)
    func gasPrice(completionHandler: @escaping (Result<BigUInt, EthereumClientError>) -> Void)
    func estimateGas(_ transaction: ZKSyncTransaction, completion: @escaping((EthereumClientError?, BigUInt?) -> Void))
    
    func eth_sendRawZKSyncTransaction(_ transaction: ZKSyncTransaction, withAccount account: EthereumAccountProtocol) async throws -> String
    func gasPrice() async throws -> BigUInt
    func estimateGas(_ transaction: ZKSyncTransaction) async throws -> BigUInt
}

extension EthereumClient {
    public func eth_sendRawZKSyncTransaction(_ transaction: ZKSyncTransaction, withAccount account: EthereumAccountProtocol, completionHandler: @escaping (Result<String, EthereumClientError>) -> Void) {
        concurrentQueue.addOperation {
            let group = DispatchGroup()
            group.enter()

            // Inject pending nonce
            self.eth_getTransactionCount(address: account.address, block: .Pending) { (error, count) in
                guard let nonce = count else {
                    group.leave()
                    return completionHandler(.failure(.unexpectedReturnValue))
                }

                var transaction = transaction
                transaction.nonce = nonce
                
                if transaction.chainId == nil, let network = self.network {
                    transaction.chainId = network.intValue
                }

                guard let signedTx = try? account.sign(zkTransaction: transaction),
                      let transactionHex = signedTx.raw?.web3.hexString else {
                    group.leave()
                    return completionHandler(.failure(.encodeIssue))
                }

                EthereumRPC.execute(session: self.session, url: self.url, method: "eth_sendRawTransaction", params: [transactionHex], receive: String.self) { (error, response) in
                    group.leave()
                    if let resDataString = response as? String {
                        completionHandler(.success(resDataString))
                    } else {
                        
                        if case let .executionError(result) = error as? JSONRPCError {
                            completionHandler(.failure(.executionError(result.error)))
                        } else {
                            completionHandler(.failure(.unexpectedReturnValue))
                        }
                    }
                }

            }
            group.wait()
        }
    }
    
    public func gasPrice(completionHandler: @escaping (Result<BigUInt, EthereumClientError>) -> Void) {
        let emptyParams: Array<Bool> = []
        EthereumRPC.execute(session: session, url: url, method: "eth_gasPrice", params: emptyParams, receive: String.self) { (error, response) in
            if let value = (response as? String).flatMap(BigUInt.init(hex:)) {
                completionHandler(.success(value))
            } else {
                completionHandler(.failure(EthereumClientError.unexpectedReturnValue))
            }
        }
    }
    
    public func estimateGas(_ transaction: ZKSyncTransaction, completion: @escaping((EthereumClientError?, BigUInt?) -> Void)) {

        let value = transaction.value > .zero ? transaction.value : nil
        let params = EstimateGasParams(from: transaction.from.value,
                                to: transaction.to.value,
                                gas: transaction.gasLimit?.web3.hexString,
                                gasPrice: transaction.gasPrice?.web3.hexString,
                                value: value?.web3.hexString,
                                data: transaction.data.web3.hexString)
        EthereumRPC.execute(session: session, url: url, method: "eth_estimateGas", params: params, receive: String.self) { (error, response) in
            if let gasHex = response as? String, let gas = BigUInt(hex: gasHex) {
                completion(nil, gas)
            } else if case let .executionError(result) = error as? JSONRPCError {
                completion(.executionError(result.error), nil)
            } else {
                completion(.unexpectedReturnValue, nil)
            }
        }
    }
}
    // MARK: - Async functions
extension EthereumClientProtocol {
    public func eth_sendRawZKSyncTransaction(_ transaction: ZKSyncTransaction, withAccount account: EthereumAccountProtocol) async throws -> String {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            eth_sendRawZKSyncTransaction(transaction, withAccount: account, completionHandler: continuation.resume)
        }
    }
    
    public func gasPrice() async throws -> BigUInt {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<BigUInt, Error>) in
            gasPrice(completionHandler: continuation.resume)
        }
    }
    
    public func estimateGas(_ transaction: ZKSyncTransaction) async throws -> BigUInt {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<BigUInt, Error>) in
            estimateGas(transaction) { error, gas in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let gas = gas {
                    continuation.resume(returning: gas)
                }
            }
        }
    }
}
