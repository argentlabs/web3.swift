//
//  web3.swift
//  Copyright © Argent Labs Limited. All rights reserved.
//

import BigInt
import Foundation

public enum CallResolution: Sendable {
    case noOffchain(failOnExecutionError: Bool)
    case offchainAllowed(maxRedirects: Int)
}

//  MARK: EthereumClient (HTTP or Websocket)

public protocol EthereumClientProtocol: EthereumRPCProtocol, AnyObject {
    // Legacy result-based API
    func net_version(completionHandler: @Sendable @escaping (Result<EthereumNetwork, EthereumClientError>) -> Void)
    func eth_gasPrice(completionHandler: @Sendable @escaping (Result<BigUInt, EthereumClientError>) -> Void)
    func eth_blockNumber(completionHandler: @Sendable @escaping (Result<Int, EthereumClientError>) -> Void)
    func eth_getBalance(address: EthereumAddress, block: EthereumBlock, completionHandler: @Sendable @escaping (Result<BigUInt, EthereumClientError>) -> Void)
    func eth_getCode(address: EthereumAddress, block: EthereumBlock, completionHandler: @Sendable @escaping (Result<String, EthereumClientError>) -> Void)
    func eth_estimateGas(_ transaction: EthereumTransaction, completionHandler: @Sendable @escaping (Result<BigUInt, EthereumClientError>) -> Void)
    func eth_sendRawTransaction(_ transaction: EthereumTransaction, withAccount account: EthereumAccountProtocol, completionHandler: @Sendable @escaping (Result<String, EthereumClientError>) -> Void)
    func eth_getTransactionCount(address: EthereumAddress, block: EthereumBlock, completionHandler: @Sendable @escaping (Result<Int, EthereumClientError>) -> Void)
    func eth_getTransaction(byHash txHash: String, completionHandler: @Sendable @escaping (Result<EthereumTransaction, EthereumClientError>) -> Void)
    func eth_getTransactionReceipt(txHash: String, completionHandler: @Sendable @escaping (Result<EthereumTransactionReceipt, EthereumClientError>) -> Void)
    func eth_call(
        _ transaction: EthereumTransaction,
        block: EthereumBlock,
        completionHandler: @Sendable @escaping (Result<String, EthereumClientError>) -> Void
    )
    func eth_call(
        _ transaction: EthereumTransaction,
        resolution: CallResolution,
        block: EthereumBlock,
        completionHandler: @Sendable @escaping (Result<String, EthereumClientError>) -> Void
    )
    func eth_getLogs(addresses: [EthereumAddress]?, topics: [String?]?, fromBlock: EthereumBlock, toBlock: EthereumBlock, completionHandler: @Sendable @escaping (Result<[EthereumLog], EthereumClientError>) -> Void)
    func eth_getLogs(addresses: [EthereumAddress]?, orTopics: [[String]?]?, fromBlock: EthereumBlock, toBlock: EthereumBlock, completionHandler: @Sendable @escaping (Result<[EthereumLog], EthereumClientError>) -> Void)
    func eth_getBlockByNumber(_ block: EthereumBlock, completionHandler: @Sendable @escaping (Result<EthereumBlockInfo, EthereumClientError>) -> Void)
    func getLogs(addresses: [EthereumAddress]?, topics: Topics?, fromBlock: EthereumBlock, toBlock: EthereumBlock) async throws -> [EthereumLog]
}

// MARK: - Websocket
#if canImport(NIO)
    import NIOWebSocket

    public protocol EthereumClientWebSocketProtocol: EthereumClientProtocol {
        var delegate: EthereumWebSocketClientDelegate? { get set }
        var currentState: WebSocketState { get }

        func connect()
        func disconnect(code: WebSocketErrorCode)
        func refresh()

        func subscribe(type: EthereumSubscriptionType, completionHandler: @Sendable @escaping (Result<EthereumSubscription, EthereumClientError>) -> Void)
        func subscribe(type: EthereumSubscriptionType) async throws -> EthereumSubscription

        func unsubscribe(_ subscription: EthereumSubscription, completionHandler: @Sendable @escaping (Result<Bool, EthereumClientError>) -> Void)
        func unsubscribe(_ subscription: EthereumSubscription) async throws -> Bool

        func pendingTransactions(onSubscribe: @Sendable @escaping (Result<EthereumSubscription, EthereumClientError>) -> Void, onData: @Sendable @escaping (String) -> Void)
        func pendingTransactions(onData: @Sendable @escaping (String) -> Void) async throws -> EthereumSubscription

        func newBlockHeaders(onSubscribe: @Sendable @escaping (Result<EthereumSubscription, EthereumClientError>) -> Void, onData: @Sendable @escaping (EthereumHeader) -> Void)
        func newBlockHeaders(onData: @Sendable @escaping (EthereumHeader) -> Void) async throws -> EthereumSubscription

        func logs(logsParams: LogsParams?, onSubscribe: @Sendable @escaping (Result<EthereumSubscription, EthereumClientError>) -> Void, onData: @Sendable @escaping (EthereumLog) -> Void)
        func logs(logsParams: LogsParams?, onData: @Sendable @escaping (EthereumLog) -> Void) async throws -> EthereumSubscription

        func syncing(onSubscribe: @Sendable @escaping (Result<EthereumSubscription, EthereumClientError>) -> Void, onData: @Sendable @escaping (EthereumSyncStatus) -> Void)
        func syncing(onData: @Sendable @escaping (EthereumSyncStatus) -> Void) async throws -> EthereumSubscription
    }

    public protocol EthereumWebSocketClientDelegate: AnyObject {
        func onNewPendingTransaction(subscription: EthereumSubscription, txHash: String)
        func onNewBlockHeader(subscription: EthereumSubscription, header: EthereumHeader)
        func onLog(subscription: EthereumSubscription, log: EthereumLog)
        func onSyncing(subscription: EthereumSubscription, sync: EthereumSyncStatus)
        func onWebSocketReconnect()
    }

    extension EthereumWebSocketClientDelegate {
        func onNewPendingTransaction(subscription: EthereumSubscription, txHash: String) {}

        func onNewBlockHeader(subscription: EthereumSubscription, header: EthereumHeader) {}

        func onLog(subscription: EthereumSubscription, log: EthereumLog) {}

        func onSyncing(subscription: EthereumSubscription, sync: EthereumSyncStatus) {}

        func onWebSocketReconnect() {}
    }

#endif
