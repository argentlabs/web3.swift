//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

public struct EquatableError: Error, Equatable {
    let base: Error

    public static func == (lhs: EquatableError, rhs: EquatableError) -> Bool {
        type(of: lhs.base) == type(of: rhs.base) &&
            lhs.base.localizedDescription == rhs.base.localizedDescription
    }
}

public enum EthereumClientError: Error, Equatable {
    case tooManyResults
    case executionError(JSONRPCErrorDetail)
    case unexpectedReturnValue
    case noResultFound
    case decodeIssue
    case encodeIssue
    case noInputData
    case webSocketError(EquatableError)
    case connectionNotOpen
}

public protocol EthereumRPCProtocol: AnyObject {
    var networkProvider: NetworkProviderProtocol { get }
    var network: EthereumNetwork? { get }

    func eth_getTransactionCount(address: EthereumAddress, block: EthereumBlock) async throws -> Int
}

public extension EthereumRPCProtocol {
    func eth_getTransactionCount(address: EthereumAddress, block: EthereumBlock) async throws -> Int {
        do {
            let data = try await networkProvider.send(method: "eth_getTransactionCount", params: [address.asString(), block.stringValue], receive: String.self)
            if let resString = data as? String, let count = Int(hex: resString) {
                return count
            } else {
                throw EthereumClientError.unexpectedReturnValue
            }
        } catch {
            throw failureHandler(error)
        }
    }

    func failureHandler(_ error: Error) -> EthereumClientError {
        if case let .executionError(result) = error as? JSONRPCError {
            return EthereumClientError.executionError(result.error)
        } else if case .executionError = error as? EthereumClientError, let error = error as? EthereumClientError {
            return error
        } else {
            return EthereumClientError.unexpectedReturnValue
        }
    }
}
