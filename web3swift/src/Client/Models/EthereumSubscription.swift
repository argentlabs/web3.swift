//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation

public enum EthereumSubscriptionType: Equatable, Hashable {
    case newBlockHeaders
    case logs(LogsParams?)
    case newPendingTransactions
    case syncing

    var params: [EthereumSubscriptionParamElement] {
        switch self {
        case .newBlockHeaders:
            return [.method("newHeads")]
        case let .logs(params):
            return [.method("logs"), .logsParams(params ?? .init(address: nil, topics: nil))]
        case .newPendingTransactions:
            return [.method("newPendingTransactions")]
        case .syncing:
            return [.method("syncing")]
        }
    }
}

public struct EthereumSubscription: Hashable {
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
public struct LogsParams: Codable, Equatable, Hashable {
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
