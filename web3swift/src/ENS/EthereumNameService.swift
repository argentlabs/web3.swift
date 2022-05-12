//
//  EthereumNameService.swift
//  web3swift
//
//  Created by Matt Marshall on 06/03/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation

protocol EthereumNameServiceProtocol {
    init(client: EthereumClientProtocol, registryAddress: EthereumAddress?)
    func resolve(address: EthereumAddress, completion: @escaping((EthereumNameServiceError?, String?) -> Void)) -> Void
    func resolve(ens: String, completion: @escaping((EthereumNameServiceError?, EthereumAddress?) -> Void)) -> Void

#if compiler(>=5.5) && canImport(_Concurrency)
    @available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
    func resolve(address: EthereumAddress) async throws -> String

    @available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
    func resolve(ens: String) async throws -> EthereumAddress
#endif
}

public enum EthereumNameServiceError: Error, Equatable {
    case noNetwork
    case noResolver
    case ensUnknown
    case invalidInput
    case decodeIssue
}

// This is an example of interacting via a JSON Definition contract API
public class EthereumNameService: EthereumNameServiceProtocol {
    let client: EthereumClientProtocol
    let registryAddress: EthereumAddress?

    required public init(client: EthereumClientProtocol, registryAddress: EthereumAddress? = nil) {
        self.client = client
        self.registryAddress = registryAddress
    }

    public func resolve(address: EthereumAddress, completion: @escaping ((EthereumNameServiceError?, String?) -> Void)) {
        guard
            let network = client.network,
            let registryAddress = self.registryAddress ?? ENSContracts.registryAddress(for: network) else {
                return completion(EthereumNameServiceError.noNetwork, nil)
            }

        let ensReverse = address.value.web3.noHexPrefix + ".addr.reverse"
        let nameHash = Self.nameHash(name: ensReverse)

        let function = ENSContracts.ENSRegistryFunctions.resolver(contract: registryAddress,
                                                                  _node: nameHash.web3.hexData ?? Data())
        guard let registryTransaction = try? function.transaction() else {
            completion(EthereumNameServiceError.invalidInput, nil)
            return
        }

        client.eth_call(registryTransaction, block: .Latest, completion: { (error, resolverData) in
            if case .executionError = error {
                return completion(.ensUnknown, nil)
            }

            guard let resolverData = resolverData else {
                return completion(EthereumNameServiceError.noResolver, nil)
            }

            guard resolverData != "0x" else {
                return completion(EthereumNameServiceError.ensUnknown, nil)
            }

            let idx = resolverData.index(resolverData.endIndex, offsetBy: -40)
            let resolverAddress = EthereumAddress(String(resolverData[idx...]).web3.withHexPrefix)

            let function = ENSContracts.ENSResolverFunctions.name(contract: resolverAddress,
                                                                  _node: nameHash.web3.hexData ?? Data())
            guard let addressTransaction = try? function.transaction() else {
                completion(EthereumNameServiceError.invalidInput, nil)
                return
            }

            self.client.eth_call(addressTransaction, block: .Latest, completion: { (error, data) in
                guard let data = data, data != "0x" else {
                    return completion(EthereumNameServiceError.ensUnknown, nil)
                }
                if let ensHex: String = try? (try? ABIDecoder.decodeData(data, types: [String.self]))?.first?.decoded() {
                    completion(nil, ensHex)
                } else {
                    completion(EthereumNameServiceError.decodeIssue, nil)
                }

            })
        })
    }

    public func resolve(ens: String, completion: @escaping ((EthereumNameServiceError?, EthereumAddress?) -> Void)) {

        guard
            let network = client.network,
            let registryAddress = self.registryAddress ?? ENSContracts.registryAddress(for: network) else {
                return completion(EthereumNameServiceError.noNetwork, nil)
            }
        let nameHash = Self.nameHash(name: ens)
        let function = ENSContracts.ENSRegistryFunctions.resolver(contract: registryAddress,
                                                                  _node: nameHash.web3.hexData ?? Data())

        guard let registryTransaction = try? function.transaction() else {
            completion(EthereumNameServiceError.invalidInput, nil)
            return
        }

        client.eth_call(registryTransaction, block: .Latest, completion: { (error, resolverData) in
            if case .executionError = error {
                return completion(.ensUnknown, nil)
            }
            
            guard let resolverData = resolverData else {
                return completion(EthereumNameServiceError.noResolver, nil)
            }

            guard resolverData != "0x" else {
                return completion(EthereumNameServiceError.ensUnknown, nil)
            }

            let idx = resolverData.index(resolverData.endIndex, offsetBy: -40)
            let resolverAddress = EthereumAddress(String(resolverData[idx...]).web3.withHexPrefix)

            let function = ENSContracts.ENSResolverFunctions.addr(contract: resolverAddress, _node: nameHash.web3.hexData ?? Data())
            guard let addressTransaction = try? function.transaction() else {
                completion(EthereumNameServiceError.invalidInput, nil)
                return
            }

            self.client.eth_call(addressTransaction, block: .Latest, completion: { (error, data) in
                guard let data = data, data != "0x" else {
                    return completion(EthereumNameServiceError.ensUnknown, nil)
                }

                if let ensAddress: EthereumAddress = try? (try? ABIDecoder.decodeData(data, types: [EthereumAddress.self]))?.first?.decoded() {
                    completion(nil, ensAddress)
                } else {
                    completion(EthereumNameServiceError.decodeIssue, nil)
                }
            })
        })
    }

    static func nameHash(name: String) -> String {
        var node = Data.init(count: 32)
        let labels = name.components(separatedBy: ".")
        for label in labels.reversed() {
            node.append(label.web3.keccak256)
            node = node.web3.keccak256
        }
        return node.web3.hexString
    }

}

#if compiler(>=5.5) && canImport(_Concurrency)

@available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
extension EthereumNameService {
    public func resolve(address: EthereumAddress) async throws -> String {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            resolve(address: address) { error, ensHex in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let ensHex = ensHex {
                    continuation.resume(returning: ensHex)
                }
            }
        }
    }

    public func resolve(ens: String) async throws -> EthereumAddress {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<EthereumAddress, Error>) in
            resolve(ens: ens) { error, address in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let address = address {
                    continuation.resume(returning: address)
                }
            }
        }
    }
}

#endif
