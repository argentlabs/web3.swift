//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import BigInt
import Foundation

public protocol ERC1271Protocol {
    init(client: EthereumClientProtocol)

    func isValidSignature(contract: EthereumAddress, messageHash: Data, signature: Data) async throws -> Bool
    func isValidSignature(contract: EthereumAddress, messageHash: Data, signature: Data, completionHandler: @escaping (Result<Bool, Error>) -> Void)
}

public class ERC1271: ERC1271Protocol {
    let client: EthereumClientProtocol

    required public init(client: EthereumClientProtocol) {
        self.client = client
    }

    public func isValidSignature(contract: EthereumAddress, messageHash: Data, signature: Data) async throws -> Bool {
        let function = try ERC1271Functions.isValidSignature(contract: contract, message: messageHash, signature: signature)
        let response = try await function.call(withClient: self.client, responseType: ERC1271Responses.isValidResponse.self)
        return response.isValid
    }

    public func isValidSignature(contract: EthereumAddress, messageHash: Data, signature: Data, completionHandler: @escaping (Result<Bool, Error>) -> Void) {
        Task {
            do {
                let isValid = try await isValidSignature(contract: contract, messageHash: messageHash, signature: signature)
                completionHandler(.success(isValid))
            } catch {
                completionHandler(.failure(error))
            }
        }
    }
}
