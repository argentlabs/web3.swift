//
//  ERC1271.swift
//  
//
//  Created by Rodrigo Kreutz on 15/06/22.
//

import Foundation
import BigInt

public protocol ERC1271Protocol {
    init(client: EthereumClientProtocol)

    func isValidSignature(contract: EthereumAddress, messageHash: Data, signature: Data, completionHandler: @escaping(Result<Bool, Error>) -> Void)

    // async
    func isValidSignature(contract: EthereumAddress, messageHash: Data, signature: Data) async throws -> Bool
}

public class ERC1271: ERC1271Protocol {
    let client: EthereumClientProtocol

    required public init(client: EthereumClientProtocol) {
        self.client = client
    }

    public func isValidSignature(contract: EthereumAddress, messageHash: Data, signature: Data, completionHandler: @escaping (Result<Bool, Error>) -> Void) {
        do {
            let function = try ERC1271Functions.isValidSignature(contract: contract, message: messageHash, signature: signature)
            function.call(withClient: self.client, responseType: ERC1271Responses.isValidResponse.self) { result in
                switch result {
                    case .success(let response):
                        completionHandler(.success(response.isValid))
                    case .failure(let error):
                        completionHandler(.failure(error))
                }
            }
        } catch {
            completionHandler(.failure(error))
        }
    }

    public func isValidSignature(contract: EthereumAddress, messageHash: Data, signature: Data) async throws -> Bool {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
            isValidSignature(contract: contract, messageHash: messageHash, signature: signature, completionHandler: continuation.resume)
        }
    }
}
