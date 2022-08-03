//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import BigInt
import Foundation
import NIOWebSocket

public enum CallResolution {
    case noOffchain(failOnExecutionError: Bool)
    case offchainAllowed(maxRedirects: Int)
}

public struct EquatableError: Error, Equatable {
    let base: Error

    public static func ==(lhs: EquatableError, rhs: EquatableError) -> Bool {
        return type(of: lhs.base) == type(of: rhs.base) &&
        lhs.base.localizedDescription == rhs.base.localizedDescription
    }
}

public enum EthereumClientError: Error, Equatable {
    case tooManyResults
    case executionError(JSONRPCErrorDetail)
    case unexpectedReturnValue
    case noResultFound
    case decodeIssue
    case encodeIssue
    case noInputData
    case webSocketError(EquatableError)
    case connectionNotOpen
}

public protocol EthereumClientProtocol: AnyObject {
    var network: EthereumNetwork? { get }

    func net_version(completionHandler: @escaping(Result<EthereumNetwork, EthereumClientError>) -> Void)
    func eth_gasPrice(completionHandler: @escaping(Result<BigUInt, EthereumClientError>) -> Void)
    func eth_blockNumber(completionHandler: @escaping(Result<Int, EthereumClientError>) -> Void)
    func eth_getBalance(address: EthereumAddress, block: EthereumBlock, completionHandler: @escaping(Result<BigUInt, EthereumClientError>) -> Void)
    func eth_getCode(address: EthereumAddress, block: EthereumBlock, completionHandler: @escaping(Result<String, EthereumClientError>) -> Void)
    func eth_estimateGas(_ transaction: EthereumTransaction, completionHandler: @escaping(Result<BigUInt, EthereumClientError>) -> Void)
    func eth_sendRawTransaction(_ transaction: EthereumTransaction, withAccount account: EthereumAccountProtocol, completionHandler: @escaping(Result<String, EthereumClientError>) -> Void)
    func eth_getTransactionCount(address: EthereumAddress, block: EthereumBlock, completionHandler: @escaping(Result<Int, EthereumClientError>) -> Void)
    func eth_getTransaction(byHash txHash: String, completionHandler: @escaping(Result<EthereumTransaction, EthereumClientError>) -> Void)
    func eth_getTransactionReceipt(txHash: String, completionHandler: @escaping(Result<EthereumTransactionReceipt, EthereumClientError>) -> Void)
    func eth_call(
        _ transaction: EthereumTransaction,
        block: EthereumBlock,
        completionHandler: @escaping(Result<String, EthereumClientError>) -> Void)
    func eth_call(
        _ transaction: EthereumTransaction,
        resolution: CallResolution,
        block: EthereumBlock,
        completionHandler: @escaping(Result<String, EthereumClientError>) -> Void)
    func eth_getLogs(addresses: [EthereumAddress]?, topics: [String?]?, fromBlock: EthereumBlock, toBlock: EthereumBlock, completionHandler: @escaping(Result<[EthereumLog], EthereumClientError>) -> Void)
    func eth_getLogs(addresses: [EthereumAddress]?, orTopics: [[String]?]?, fromBlock: EthereumBlock, toBlock: EthereumBlock, completionHandler: @escaping(Result<[EthereumLog], EthereumClientError>) -> Void)
    func eth_getBlockByNumber(_ block: EthereumBlock, completionHandler: @escaping(Result<EthereumBlockInfo, EthereumClientError>) -> Void)
    func getLogs(addresses: [EthereumAddress]?, topics: Topics?, fromBlock: EthereumBlock, toBlock: EthereumBlock) async throws -> [EthereumLog]

    // Async/Await
    func net_version() async throws -> EthereumNetwork
    func eth_gasPrice() async throws -> BigUInt
    func eth_blockNumber() async throws -> Int
    func eth_getBalance(address: EthereumAddress, block: EthereumBlock) async throws -> BigUInt
    func eth_getCode(address: EthereumAddress, block: EthereumBlock) async throws -> String
    func eth_estimateGas(_ transaction: EthereumTransaction) async throws -> BigUInt
    func eth_sendRawTransaction(_ transaction: EthereumTransaction, withAccount account: EthereumAccountProtocol) async throws -> String
    func eth_getTransactionCount(address: EthereumAddress, block: EthereumBlock) async throws -> Int
    func eth_getTransaction(byHash txHash: String) async throws -> EthereumTransaction
    func eth_getTransactionReceipt(txHash: String) async throws -> EthereumTransactionReceipt
    func eth_call(
        _ transaction: EthereumTransaction,
        block: EthereumBlock
    ) async throws -> String
    func eth_call(
        _ transaction: EthereumTransaction,
        resolution: CallResolution,
        block: EthereumBlock
    ) async throws -> String
    func eth_getLogs(addresses: [EthereumAddress]?, topics: [String?]?, fromBlock: EthereumBlock, toBlock: EthereumBlock) async throws ->  [EthereumLog]
    func eth_getLogs(addresses: [EthereumAddress]?, orTopics: [[String]?]?, fromBlock: EthereumBlock, toBlock: EthereumBlock) async throws ->  [EthereumLog]
    func eth_getBlockByNumber(_ block: EthereumBlock) async throws -> EthereumBlockInfo
}

public protocol EthereumClientWebSocketProtocol: EthereumClientProtocol {
    var delegate: EthereumWebSocketClientDelegate? { get set }
    var currentState: WebSocketState { get }

    func connect()
    func disconnect(code: WebSocketErrorCode)
    func refresh()

    func subscribe(type: EthereumSubscriptionType, completionHandler: @escaping(Result<EthereumSubscription, EthereumClientError>) -> Void)
    func subscribe(type: EthereumSubscriptionType) async throws -> EthereumSubscription

    func unsubscribe(_ subscription: EthereumSubscription, completionHandler: @escaping(Result<Bool, EthereumClientError>) -> Void)
    func unsubscribe(_ subscription: EthereumSubscription) async throws -> Bool

    func pendingTransactions(onSubscribe: @escaping(Result<EthereumSubscription, EthereumClientError>) -> Void, onData: @escaping(String) -> Void)
    func pendingTransactions(onData: @escaping(String) -> Void) async throws -> EthereumSubscription

    func newBlockHeaders(onSubscribe: @escaping(Result<EthereumSubscription, EthereumClientError>) -> Void, onData: @escaping(EthereumHeader) -> Void)
    func newBlockHeaders(onData: @escaping(EthereumHeader) -> Void) async throws -> EthereumSubscription

    func syncing(onSubscribe: @escaping(Result<EthereumSubscription, EthereumClientError>) -> Void, onData: @escaping(EthereumSyncStatus) -> Void)
    func syncing(onData: @escaping(EthereumSyncStatus) -> Void) async throws -> EthereumSubscription
}

public protocol EthereumWebSocketClientDelegate: AnyObject {
    func onNewPendingTransaction(subscription: EthereumSubscription, txHash: String)
    func onNewBlockHeader(subscription: EthereumSubscription, header: EthereumHeader)
    func onSyncing(subscription: EthereumSubscription, sync: EthereumSyncStatus)
    func onWebSocketReconnect()
}

extension EthereumWebSocketClientDelegate {
    func onNewPendingTransaction(subscription: EthereumSubscription, txHash: String) {}

    func onNewBlockHeader(subscription: EthereumSubscription, header: EthereumHeader) {}

    func onSyncing(subscription: EthereumSubscription, sync: EthereumSyncStatus) {}

    func onWebSocketReconnect() {}
}
