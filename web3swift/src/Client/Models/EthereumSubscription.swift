//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation

public enum EthereumSubscriptionType: Equatable, Hashable {
    case newBlockHeaders
    case pendingTransactions
    case syncing

    var method: String {
        switch self {
        case .newBlockHeaders:
            return "newHeads"
        case .pendingTransactions:
            return "newPendingTransactions"
        case .syncing:
            return "syncing"
        }
    }

    struct LogParams: Encodable {
        let address: [EthereumAddress]
        let topics: [String?]
    }

    var params: String? {
        return nil
    }
}

public struct EthereumSubscription: Hashable {
    let type: EthereumSubscriptionType
    let id: String
}
