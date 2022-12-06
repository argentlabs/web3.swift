//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import BigInt
import Foundation

public enum ERC721Events {
    public struct Transfer: ABIEvent {
        public static let name = "Transfer"
        public static let types: [ABIType.Type] = [EthereumAddress.self, EthereumAddress.self, BigUInt.self]
        public static let typesIndexed = [true, true, true]
        public let log: EthereumLog

        public let from: EthereumAddress
        public let to: EthereumAddress
        public let tokenId: BigUInt

        public init?(topics: [ABIDecoder.DecodedValue], data: [ABIDecoder.DecodedValue], log: EthereumLog) throws {
            try Transfer.checkParameters(topics, data)
            self.log = log

            self.from = try topics[0].decoded()
            self.to = try topics[1].decoded()
            self.tokenId = try topics[2].decoded()
        }
    }

    public struct Approval: ABIEvent {
        public static let name = "Approval"
        public static let types: [ABIType.Type] = [EthereumAddress.self, EthereumAddress.self, BigUInt.self]
        public static let typesIndexed = [true, true, true]
        public let log: EthereumLog

        public let from: EthereumAddress
        public let approved: EthereumAddress
        public let tokenId: BigUInt

        public init?(topics: [ABIDecoder.DecodedValue], data: [ABIDecoder.DecodedValue], log: EthereumLog) throws {
            try Approval.checkParameters(topics, data)
            self.log = log

            self.from = try topics[0].decoded()
            self.approved = try topics[1].decoded()
            self.tokenId = try topics[2].decoded()
        }
    }

    public struct ApprovalForAll: ABIEvent {
        public static let name = "ApprovalForAll"
        public static let types: [ABIType.Type] = [EthereumAddress.self, EthereumAddress.self, BigUInt.self]
        public static let typesIndexed = [true, true, true]
        public let log: EthereumLog

        public let from: EthereumAddress
        public let `operator`: EthereumAddress
        public let approved: Bool

        public init?(topics: [ABIDecoder.DecodedValue], data: [ABIDecoder.DecodedValue], log: EthereumLog) throws {
            try ApprovalForAll.checkParameters(topics, data)
            self.log = log

            self.from = try topics[0].decoded()
            self.operator = try topics[1].decoded()
            self.approved = try topics[2].decoded()
        }
    }
}
