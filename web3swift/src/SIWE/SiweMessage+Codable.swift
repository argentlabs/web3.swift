//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation

extension SiweMessage: Codable {
    enum CodingKeys: String, CaseIterable, CodingKey {
        case domain
        case address
        case statement
        case uri
        case version
        case chainId
        case nonce
        case issuedAt
        case expirationTime
        case notBefore
        case requestId
        case resources
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.domain = try container.decode(String.self, forKey: .domain)
        self.address = try container.decode(String.self, forKey: .address)
        self.statement = try container.decodeIfPresent(String.self, forKey: .statement)
        self.uri = try container.decode(URL.self, forKey: .uri)
        self.version = try container.decode(String.self, forKey: .version)
        if let chainIdString = try? container.decode(String.self, forKey: .chainId),
           let chainId = Int(chainIdString) {
            self.chainId = chainId
        } else {
            self.chainId = try container.decode(Int.self, forKey: .chainId)
        }
        self.nonce = try container.decode(String.self, forKey: .nonce)
        self.issuedAt = try container.decode(Date.self, forKey: .issuedAt)
        self.expirationTime = try container.decodeIfPresent(Date.self, forKey: .expirationTime)
        self.notBefore = try container.decodeIfPresent(Date.self, forKey: .notBefore)
        self.requestId = try container.decodeIfPresent(String.self, forKey: .requestId)
        self.resources = try container.decodeIfPresent([URL].self, forKey: .resources)

        try validate()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(domain, forKey: .domain)
        try container.encode(address, forKey: .address)
        try container.encodeIfPresent(statement, forKey: .statement)
        try container.encode(uri, forKey: .uri)
        try container.encode(version, forKey: .version)
        try container.encode(chainId, forKey: .chainId)
        try container.encode(nonce, forKey: .nonce)
        try container.encode(issuedAt, forKey: .issuedAt)
        try container.encodeIfPresent(expirationTime, forKey: .expirationTime)
        try container.encodeIfPresent(notBefore, forKey: .notBefore)
        try container.encodeIfPresent(requestId, forKey: .requestId)
        try container.encodeIfPresent(resources, forKey: .resources)
    }
}
