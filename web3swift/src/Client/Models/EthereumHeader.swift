//
//  EthereumHeader.swift
//  web3swift
//
//  Created by Dionisios Karatzas on 8/6/22.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation

public struct EthereumHeader: Codable {
    public let parentHash: String
    public let sha3Uncles: String
    public let miner: String
    public let stateRoot: String
    public let transactionsRoot: String
    public let receiptsRoot: String
    public let logsBloom: String
    public let difficulty: String
    public let number: String
    public let gasLimit: String
    public let gasUsed: String
    public let timestamp: String
    public let extraData: String
    public let mixHash: String
    public let nonce: String
    public let hash: String
}
