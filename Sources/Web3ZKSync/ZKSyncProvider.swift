//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import web3
import BigInt
import Logging
import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

public protocol ZKSyncClientProtocol: EthereumRPCProtocol {
    func eth_sendRawZKSyncTransaction(_ transaction: ZKSyncTransaction, withAccount account: EthereumAccountProtocol) async throws -> String
    func gasPrice() async throws -> BigUInt
    func estimateGas(_ transaction: ZKSyncTransaction) async throws -> BigUInt
}

extension ZKSyncClientProtocol {
    public func eth_sendRawZKSyncTransaction(_ transaction: ZKSyncTransaction, withAccount account: EthereumAccountProtocol) async throws -> String {
        // Inject pending nonce
        let nonce = try await self.eth_getTransactionCount(address: account.address, block: .Pending)

        var transaction = transaction
        transaction.nonce = nonce

        if transaction.chainId == nil {
            transaction.chainId = network.intValue
        }

        guard let signedTx = try? account.sign(zkTransaction: transaction),
              let transactionHex = signedTx.raw?.web3.hexString else {
            throw EthereumClientError.encodeIssue
        }

        guard let txHash = try await networkProvider.send(
            method: "eth_sendRawTransaction",
            params: [transactionHex],
            receive: String.self
        ) as? String else {
            throw EthereumClientError.unexpectedReturnValue
        }

        return txHash
    }

    public func gasPrice() async throws -> BigUInt {
        let emptyParams: [Bool] = []
        guard let data = try await networkProvider.send(method: "eth_gasPrice", params: emptyParams, receive: String.self) as? String else {
            throw EthereumClientError.unexpectedReturnValue
        }

        guard let value = BigUInt(hex: data) else {
            throw EthereumClientError.unexpectedReturnValue
        }
        return value
    }

    public func estimateGas(_ transaction: ZKSyncTransaction) async throws -> BigUInt {
        let value = transaction.value > .zero ? transaction.value : nil
        let params = EstimateGasParams(
            from: transaction.from.asString(),
            to: transaction.to.asString(),
            gas: transaction.gasLimit?.web3.hexString,
            gasPrice: transaction.gasPrice?.web3.hexString,
            value: value?.web3.hexString,
            data: transaction.data.web3.hexString
        )

        guard let data = try await networkProvider.send(
            method: "eth_estimateGas",
            params: params,
            receive: String.self
        ) as? String else {
            throw EthereumClientError.unexpectedReturnValue
        }

        guard let value = BigUInt(hex: data) else {
            throw EthereumClientError.unexpectedReturnValue
        }
        return value
    }
}

struct EstimateGasParams: Encodable {
    let from: String?
    let to: String
    let gas: String?
    let gasPrice: String?
    let value: String?
    let data: String?

    enum TransactionCodingKeys: String, CodingKey {
        case from
        case to
        case gas
        case gasPrice
        case value
        case data
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        var nested = container.nestedContainer(keyedBy: TransactionCodingKeys.self)
        if let from = from {
            try nested.encode(from, forKey: .from)
        }
        try nested.encode(to, forKey: .to)

        let jsonRPCAmount: (String) -> String = { amount in
            amount == "0x00" ? "0x0" : amount
        }

        if let gas = gas.map(jsonRPCAmount) {
            try nested.encode(gas, forKey: .gas)
        }
        if let gasPrice = gasPrice.map(jsonRPCAmount) {
            try nested.encode(gasPrice, forKey: .gasPrice)
        }
        if let value = value.map(jsonRPCAmount) {
            try nested.encode(value, forKey: .value)
        }
        if let data = data {
            try nested.encode(data, forKey: .data)
        }
    }
}

public class ZKSyncClient: BaseEthereumClient, ZKSyncClientProtocol {
    let networkQueue: OperationQueue

    public init(
        url: URL,
        sessionConfig: URLSessionConfiguration = URLSession.shared.configuration,
        logger: Logger? = nil,
        network: EthereumNetwork
    ) {
        let networkQueue = OperationQueue()
        networkQueue.name = "web3swift.client.networkQueue"
        networkQueue.maxConcurrentOperationCount = 4
        self.networkQueue = networkQueue

        let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: networkQueue)
        super.init(networkProvider: HttpNetworkProvider(session: session, url: url), url: url, logger: logger, network: network)
    }
}
