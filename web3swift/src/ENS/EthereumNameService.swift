//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import BigInt
import Foundation

public enum ResolutionMode {
    case onchain
    case allowOffchainLookup
}

protocol EthereumNameServiceProtocol {
    func resolve(
        address: EthereumAddress,
        mode: ResolutionMode,
        completionHandler: @escaping (Result<String, EthereumNameServiceError>) -> Void
    )
    func resolve(
        ens: String,
        mode: ResolutionMode,
        completionHandler: @escaping (Result<EthereumAddress, EthereumNameServiceError>) -> Void
    )

    func resolve(address: EthereumAddress, mode: ResolutionMode) async throws -> String

    func resolve(ens: String, mode: ResolutionMode) async throws -> EthereumAddress
}

public enum EthereumNameServiceError: Error, Equatable {
    case noNetwork
    case ensUnknown
    case invalidInput
    case decodeIssue
    case tooManyRedirections
}

public class EthereumNameService: EthereumNameServiceProtocol {
    let client: EthereumRPCProtocol
    let registryAddress: EthereumAddress?
    let maximumRedirections: Int
    private let syncQueue = DispatchQueue(label: "web3swift.ethereumNameService.syncQueue")

    private var _resolversByAddress = [EthereumAddress: ENSResolver]()
    var resolversByAddress: [EthereumAddress: ENSResolver] {
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
        client: EthereumRPCProtocol,
        registryAddress: EthereumAddress? = nil,
        maximumRedirections: Int = 5
    ) {
        self.client = client
        self.registryAddress = registryAddress
        self.maximumRedirections = maximumRedirections
    }

    private var network: EthereumNetwork {
        client.network
    }

    public func resolve(address: EthereumAddress, mode: ResolutionMode) async throws -> String {
        guard let registryAddress = registryAddress ?? ENSContracts.registryAddress(for: network) else {
            throw EthereumNameServiceError.noNetwork
        }

        do {
            let resolver = try await getResolver(
                for: address,
                registryAddress: registryAddress,
                mode: mode
            )

            let name = try await resolver.resolve(address: address)
            return name
        } catch {
            throw error as? EthereumNameServiceError ?? EthereumNameServiceError.ensUnknown
        }
    }

    public func resolve(ens: String, mode: ResolutionMode) async throws -> EthereumAddress {
        guard let registryAddress = registryAddress ?? ENSContracts.registryAddress(for: network) else {
            throw EthereumNameServiceError.noNetwork
        }
        do {
            let (resolver, supportingWildCard) = try await getResolver(
                for: ens,
                fullName: ens,
                registryAddress: registryAddress,
                mode: mode
            )

            let address = try await resolver.resolve(name: ens, supportingWildcard: supportingWildCard)
            return address
        } catch {
            throw error as? EthereumNameServiceError ?? EthereumNameServiceError.ensUnknown
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
        mode: ResolutionMode,
        completionHandler: @escaping (Result<String, EthereumNameServiceError>) -> Void
    ) {
        Task {
            do {
                let name = try await resolve(address: address, mode: mode)
                completionHandler(.success(name))
            } catch {
                completionHandler(.failure(error as? EthereumNameServiceError ?? .ensUnknown))
            }
        }
    }

    public func resolve(
        ens: String,
        mode: ResolutionMode,
        completionHandler: @escaping (Result<EthereumAddress, EthereumNameServiceError>) -> Void
    ) {
        Task {
            do {
                let address = try await resolve(ens: ens, mode: mode)
                completionHandler(.success(address))
            } catch {
                completionHandler(.failure(error as? EthereumNameServiceError ?? .ensUnknown))
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

extension EthereumNameService {
    private func getResolver(
        for address: EthereumAddress,
        registryAddress: EthereumAddress,
        mode: ResolutionMode
    ) async throws -> ENSResolver {
        let function = ENSContracts.ENSRegistryFunctions.resolver(contract: registryAddress, parameter: .address(address))

        do {
            let resolverAddress = try await function.call(
                withClient: client,
                responseType: ENSContracts.AddressResponse.self,
                block: .Latest,
                resolution: .noOffchain(failOnExecutionError: true)
            ).value

            let resolver = resolversByAddress[resolverAddress] ?? ENSResolver(
                address: resolverAddress,
                client: client,
                callResolution: mode.callResolution(maxRedirects: maximumRedirections)
            )
            resolversByAddress[resolverAddress] = resolver
            return resolver
        } catch {
            throw EthereumNameServiceError.ensUnknown
        }
    }

    private func getResolver(
        for name: String,
        fullName: String,
        registryAddress: EthereumAddress,
        mode: ResolutionMode
    ) async throws -> (ENSResolver, Bool) {
        let function = ENSContracts.ENSRegistryFunctions.resolver(contract: registryAddress, parameter: .name(name))

        do {
            let resolverAddress = try await function.call(
                withClient: client,
                responseType: ENSContracts.AddressResponse.self,
                block: .Latest,
                resolution: .noOffchain(failOnExecutionError: true)
            ).value

            guard resolverAddress != .zero else {
                // Wildcard name resolution (ENSIP-10)
                let parent = name.split(separator: ".").dropFirst()

                guard parent.count > 1 else {
                    throw EthereumNameServiceError.ensUnknown
                }

                let parentName = parent.joined(separator: ".")
                return try await getResolver(
                    for: parentName,
                    fullName: fullName,
                    registryAddress: registryAddress,
                    mode: mode
                )
            }

            let resolver = resolversByAddress[resolverAddress] ?? ENSResolver(
                address: resolverAddress,
                client: client,
                callResolution: mode.callResolution(maxRedirects: maximumRedirections)
            )
            resolversByAddress[resolverAddress] = resolver
            return (resolver, fullName != name)
        } catch {
            throw error as? EthereumNameServiceError ?? .ensUnknown
        }
    }
}
