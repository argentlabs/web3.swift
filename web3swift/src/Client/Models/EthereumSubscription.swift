//
//  web3.swift
//  Copyright © Argent Labs Limited. All rights reserved.
//

import Foundation

public enum EthereumSubscriptionType: Sendable, Equatable, Hashable {
    case newBlockHeaders
    case logs(LogsParams?)
    case newPendingTransactions
    case syncing

    var params: [EthereumSubscriptionParamElement] {
        switch self {
        case .newBlockHeaders:
            [.method("newHeads")]
        case let .logs(params):
            [.method("logs"), .logsParams(params ?? .init(address: nil, topics: nil))]
        case .newPendingTransactions:
            [.method("newPendingTransactions")]
        case .syncing:
            [.method("syncing")]
        }
    }
}

public struct EthereumSubscription: Sendable, Hashable {
    let type: EthereumSubscriptionType
    let id: String
}

public enum EthereumSubscriptionParamElement: Encodable {
    case method(String)
    case logsParams(LogsParams)

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .method(x):
            try container.encode(x)
        case let .logsParams(x):
            try container.encode(x)
        }
    }
}

// MARK: - ParamClass
public struct LogsParams: Sendable, Codable, Equatable, Hashable {
    public let address: EthereumAddress?
    public let topics: [String]?

    enum CodingKeys: String, CodingKey {
        case address = "address"
        case topics = "topics"
    }

    public init(address: EthereumAddress?, topics: [String]?) {
        self.address = address
        self.topics = topics
    }
}
