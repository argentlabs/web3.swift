//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation

extension EthereumAccount {
    func signSIWERequest(_ message: String) async throws -> String {
        let message = try SiweMessage(message)
        return try await signSIWERequest(message)
    }

    func signSIWERequest(_ message: SiweMessage) async throws -> String {
        guard let data = "\(message)".data(using: .utf8) else {
            throw EthereumAccountError.signError
        }
        return try await signMessage(message: data)
    }
}
