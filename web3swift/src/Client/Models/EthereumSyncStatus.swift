//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

public struct EthereumSyncStatus: Codable {
    public let result: ResultUnion

    enum CodingKeys: String, CodingKey {
        case result
    }

    public init(result: ResultUnion) {
        self.result = result
    }
}

public enum ResultUnion: Codable {
    case bool(Bool)
    case resultClass(ResultClass)

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(Bool.self) {
            self = .bool(x)
            return
        }
        if let x = try? container.decode(ResultClass.self) {
            self = .resultClass(x)
            return
        }
        throw DecodingError.typeMismatch(ResultUnion.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for ResultUnion"))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .bool(x):
            try container.encode(x)
        case let .resultClass(x):
            try container.encode(x)
        }
    }
}

public struct ResultClass: Codable {
    public struct Status: Codable {
        public let startingBlock: Int
        public let currentBlock: Int
        public let highestBlock: Int
        public let pulledStates: Int
        public let knownStates: Int

        enum CodingKeys: String, CodingKey {
            case startingBlock
            case currentBlock
            case highestBlock
            case pulledStates
            case knownStates
        }

        public init(startingBlock: Int, currentBlock: Int, highestBlock: Int, pulledStates: Int, knownStates: Int) {
            self.startingBlock = startingBlock
            self.currentBlock = currentBlock
            self.highestBlock = highestBlock
            self.pulledStates = pulledStates
            self.knownStates = knownStates
        }
    }

    public let syncing: Bool
    public let status: Status

    enum CodingKeys: String, CodingKey {
        case syncing
        case status
    }

    public init(syncing: Bool, status: Status) {
        self.syncing = syncing
        self.status = status
    }
}
