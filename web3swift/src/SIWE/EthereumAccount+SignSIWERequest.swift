//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation

extension EthereumAccount {
    func signSIWERequest(_ message: String) throws -> String {
        let message = try SiweMessage(message)
        return try signSIWERequest(message)
    }

    func signSIWERequest(_ message: SiweMessage) throws -> String {
        guard let data = "\(message)".data(using: .utf8) else { throw EthereumAccountError.signError }
        return try signMessage(message: data)
    }
}
