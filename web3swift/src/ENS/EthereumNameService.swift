//
//  EthereumNameService.swift
//  web3swift
//
//  Created by Matt Marshall on 06/03/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation
import BigInt

public enum ResolutionMode {
    case onchain
    case allowOffchainLookup
}

protocol EthereumNameServiceProtocol {
    func resolve(
        address: EthereumAddress,
        mode: ResolutionMode,
        completion: @escaping((EthereumNameServiceError?, String?) -> Void)
    ) -> Void
    func resolve(
        ens: String,
        mode: ResolutionMode,
        completion: @escaping((EthereumNameServiceError?, EthereumAddress?) -> Void)
    ) -> Void

    func resolve(
        address: EthereumAddress,
        mode: ResolutionMode
    ) async throws -> String

    func resolve(
        ens: String,
        mode: ResolutionMode
    ) async throws -> EthereumAddress
}

public enum EthereumNameServiceError: Error, Equatable {
    case noNetwork
    case noResolver
    case ensUnknown
    case invalidInput
    case decodeIssue
    case tooManyRedirections
}

public class EthereumNameService: EthereumNameServiceProtocol {
    let client: EthereumClientProtocol
    let registryAddress: EthereumAddress?
    let maximumRedirections: Int
    private let syncQueue = DispatchQueue(label: "web3swift.ethereumNameService.syncQueue")

    private var _resolversByAddress = [EthereumAddress: ENSResolver]()
    var resolversByAddress: [EthereumAddress : ENSResolver] {
        get {
            var byAddress: [EthereumAddress: ENSResolver]!
            syncQueue.sync { byAddress = _resolversByAddress }
            return byAddress
        }
        set {
            syncQueue.async(flags: .barrier) {
                self._resolversByAddress = newValue
            }
        }
    }

    required public init(
        client: EthereumClientProtocol,
        registryAddress: EthereumAddress? = nil,
        maximumRedirections: Int = 5
    ) {
        self.client = client
        self.registryAddress = registryAddress
        self.maximumRedirections = maximumRedirections
    }

    public func resolve(
        address: EthereumAddress,
        mode: ResolutionMode,
        completion: @escaping ((EthereumNameServiceError?, String?) -> Void)
    ) {
        guard
            let network = client.network,
            let registryAddress = self.registryAddress ?? ENSContracts.registryAddress(for: network) else {
                return completion(EthereumNameServiceError.noNetwork, nil)
            }

        let function = ENSContracts.ENSRegistryFunctions.resolver(
            contract: registryAddress,
            parameter: .address(address)
        )

        function.call(
            withClient: client,
            responseType: ENSContracts.AddressResponse.self,
            block: .Latest,
            resolution: .noOffchain(failOnExecutionError: true)
        ) { (error, response) in
            if case .executionError = error {
                return completion(.ensUnknown, nil)
            }

            guard let resolverAddress = response?.value else {
                return completion(EthereumNameServiceError.noResolver, nil)
            }

            let resolver = self.resolversByAddress[resolverAddress] ?? ENSResolver(
                address: resolverAddress,
                client: self.client,
                callResolution: mode.callResolution(maxRedirects: self.maximumRedirections)
            )
            self.resolversByAddress[resolverAddress] = resolver

            Task {
                do {
                    let name = try await resolver.resolve(address: address)
                    completion(nil, name)
                } catch let error {
                    completion(error as? EthereumNameServiceError ?? .ensUnknown, nil)
                }
            }
        }
    }

    public func resolve(
        ens: String,
        mode: ResolutionMode,
        completion: @escaping ((EthereumNameServiceError?, EthereumAddress?) -> Void)
    ) {
        guard
            let network = client.network,
            let registryAddress = self.registryAddress ?? ENSContracts.registryAddress(for: network) else {
                return completion(EthereumNameServiceError.noNetwork, nil)
            }
        let function = ENSContracts.ENSRegistryFunctions.resolver(
            contract: registryAddress,
            parameter: .name(ens)
        )

        function.call(
            withClient: client,
            responseType: ENSContracts.AddressResponse.self,
            block: .Latest,
            resolution: .noOffchain(failOnExecutionError: true)
        ) { (error, response) in
            if case .executionError = error {
                return completion(.ensUnknown, nil)
            }

            guard let resolverAddress = response?.value else {
                return completion(EthereumNameServiceError.noResolver, nil)
            }

            let resolver = self.resolversByAddress[resolverAddress] ?? ENSResolver(
                address: resolverAddress,
                client: self.client,
                callResolution: mode.callResolution(maxRedirects: self.maximumRedirections)
            )
            self.resolversByAddress[resolverAddress] = resolver

            Task {
                do {
                    let address = try await resolver.resolve(name: ens)
                    completion(nil, address)
                } catch let error {
                    completion(error as? EthereumNameServiceError ?? .ensUnknown, nil)
                }
            }
        }
    }

    static func nameHash(name: String) -> String {
        ENSContracts.nameHash(name: name)
    }

    static func dnsEncode(
        name: String
    ) -> Data {
        ENSContracts.dnsEncode(name: name)
    }
}

extension EthereumNameService {
    public func resolve(
        address: EthereumAddress,
        mode: ResolutionMode
    ) async throws -> String {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            resolve(
                address: address,
                mode: mode
            ) { error, ensHex in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let ensHex = ensHex {
                    continuation.resume(returning: ensHex)
                }
            }
        }
    }

    public func resolve(
        ens: String,
        mode: ResolutionMode
    ) async throws -> EthereumAddress {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<EthereumAddress, Error>) in
            resolve(
                ens: ens,
                mode: mode
            ) { error, address in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let address = address {
                    continuation.resume(returning: address)
                }
            }
        }
    }
}


fileprivate extension ResolutionMode {
    func callResolution(maxRedirects: Int) -> CallResolution {
        switch self {
        case .allowOffchainLookup:
            return .offchainAllowed(maxRedirects: maxRedirects)
        case .onchain:
            return .noOffchain(failOnExecutionError: true)
        }
    }
}
