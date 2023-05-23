//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation

extension EthereumNameService {
    public func resolve(addresses: [EthereumAddress]) async throws -> [AddressResolveOutput] {
        try await MultiResolver(client: client, registryAddress: registryAddress)
            .resolve(addresses: addresses)
    }

    public func resolve(names: [String]) async throws -> [NameResolveOutput] {
        try await MultiResolver(client: client, registryAddress: registryAddress)
            .resolve(names: names)
    }
}

extension EthereumNameService {
    public func resolve(
        addresses: [EthereumAddress],
        completion: @escaping (Result<[AddressResolveOutput], Error>) -> Void
    ) {
        Task {
            do {
                let result = try await resolve(addresses: addresses)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }
    }

    public func resolve(
        names: [String],
        completion: @escaping (Result<[NameResolveOutput], Error>) -> Void
    ) {
        Task {
            do {
                let result = try await resolve(names: names)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }
    }
}

extension EthereumNameService {
    public enum ResolveOutput<Value: Equatable>: Equatable {
        case couldNotBeResolved(EthereumNameServiceError)
        case resolved(Value)
    }

    public struct AddressResolveOutput: Equatable {
        public let address: EthereumAddress
        public let output: ResolveOutput<String>
    }

    public struct NameResolveOutput: Equatable {
        public let ens: String
        public let output: ResolveOutput<EthereumAddress>
    }

    private class MultiResolver {
        private class RegistryOutput<ResolveOutput> {
            var queries: [ResolverQuery] = []
            var intermediaryResponses: [ResolveOutput?]

            init(expectedResponsesCount: Int) {
                self.intermediaryResponses = Array(repeating: nil, count: expectedResponsesCount)
            }
        }

        private struct ResolverQuery {
            let index: Int
            let parameter: ENSRegistryResolverParameter
            let resolverAddress: EthereumAddress
            let nameHash: Data
        }

        let client: EthereumRPCProtocol
        let registryAddress: EthereumAddress?
        let multicall: Multicall

        init(
            client: EthereumRPCProtocol,
            registryAddress: EthereumAddress? = nil
        ) {
            self.client = client
            self.registryAddress = registryAddress
            self.multicall = Multicall(client: client)
        }

        func resolve(addresses: [EthereumAddress]) async throws -> [AddressResolveOutput] {
            let output = RegistryOutput<AddressResolveOutput>(expectedResponsesCount: addresses.count)

            try await resolveRegistry(parameters: addresses.map(ENSRegistryResolverParameter.address), handler: { index, parameter, result in
                guard let address = parameter.address else {
                    return
                }
                switch result {
                case let .success(resolverAddress):
                    output.queries.append(
                        ResolverQuery(
                            index: index,
                            parameter: parameter,
                            resolverAddress: resolverAddress,
                            nameHash: parameter.nameHash
                        )
                    )
                case let .failure(error):
                    output.intermediaryResponses[index] = AddressResolveOutput(
                        address: address,
                        output: Self.output(from: error)
                    )
                }
            })

            let result = try await resolveQueries(registryOutput: output)
            return result
        }

        func resolve(names: [String]) async throws -> [NameResolveOutput] {
            let output = RegistryOutput<NameResolveOutput>(expectedResponsesCount: names.count)

            try await resolveRegistry(parameters: names.map(ENSRegistryResolverParameter.name), handler: { index, parameter, result in
                guard let name = parameter.name else {
                    return
                }
                switch result {
                case let .success(resolverAddress):
                    output.queries.append(
                        ResolverQuery(
                            index: index,
                            parameter: parameter,
                            resolverAddress: resolverAddress,
                            nameHash: parameter.nameHash
                        )
                    )
                case let .failure(error):
                    output.intermediaryResponses[index] = NameResolveOutput(
                        ens: name,
                        output: Self.output(from: error)
                    )
                }
            })

            return try await resolveQueries(registryOutput: output)
        }

        private func resolveRegistry(
            parameters: [ENSRegistryResolverParameter],
            handler: @escaping (Int, ENSRegistryResolverParameter, Result<EthereumAddress, Multicall.CallError>) -> Void
        ) async throws {
            guard let network = client.network, let ensRegistryAddress = registryAddress ?? ENSContracts.registryAddress(for: network) else {
                throw EthereumNameServiceError.noNetwork
            }

            var aggegator = Multicall.Aggregator()

            do {
                try parameters.enumerated().forEach { index, parameter in

                    let function = ENSContracts.ENSRegistryFunctions.resolver(contract: ensRegistryAddress, parameter: parameter)

                    try aggegator.append(
                        function: function,
                        response: ENSContracts.ENSRegistryResponses.RegistryResponse.self
                    ) {
                        result in handler(index, parameter, result)
                    }
                }

                do {
                    _ = try await multicall.aggregate(calls: aggegator.calls)
                } catch {
                    throw EthereumNameServiceError.noNetwork
                }
            } catch {
                throw EthereumNameServiceError.invalidInput
            }
        }

        private func resolveQueries<ResolverOutput>(registryOutput: RegistryOutput<ResolverOutput>) async throws -> [ResolverOutput] {
            var aggegator = Multicall.Aggregator()

            registryOutput.queries.forEach { query in
                switch query.parameter {
                case let .address(address):
                    guard let registryOutput = registryOutput as? RegistryOutput<AddressResolveOutput> else {
                        fatalError("Invalid registry output provided")
                    }
                    resolveAddress(query, address: address, aggegator: &aggegator, registryOutput: registryOutput)
                case let .name(name):
                    guard let registryOutput = registryOutput as? RegistryOutput<NameResolveOutput> else {
                        fatalError("Invalid registry output provided")
                    }
                    resolveName(query, ens: name, aggegator: &aggegator, registryOutput: registryOutput)
                }
            }

            do {
                _ = try await multicall.aggregate(calls: aggegator.calls)
                return registryOutput.intermediaryResponses.compactMap { $0 }
            } catch {
                throw EthereumNameServiceError.noNetwork
            }
        }

        private func resolveAddress(
            _ query: EthereumNameService.MultiResolver.ResolverQuery,
            address: EthereumAddress,
            aggegator: inout Multicall.Aggregator,
            registryOutput: RegistryOutput<AddressResolveOutput>
        ) {
            do {
                try aggegator.append(
                    function: ENSContracts.ENSResolverFunctions.name(contract: query.resolverAddress, _node: query.nameHash),
                    response: ENSContracts.ENSRegistryResponses.AddressResolverResponse.self
                ) { result in
                    switch result {
                    case let .success(name):
                        registryOutput.intermediaryResponses[query.index] = AddressResolveOutput(
                            address: address,
                            output: .resolved(name)
                        )
                    case let .failure(error):
                        registryOutput.intermediaryResponses[query.index] = AddressResolveOutput(
                            address: address,
                            output: Self.output(from: error)
                        )
                    }
                }
            } catch {
                registryOutput.intermediaryResponses[query.index] = AddressResolveOutput(
                    address: address,
                    output: Self.output(from: error)
                )
            }
        }

        private func resolveName(
            _ query: EthereumNameService.MultiResolver.ResolverQuery,
            ens: String,
            aggegator: inout Multicall.Aggregator,
            registryOutput: RegistryOutput<NameResolveOutput>
        ) {
            do {
                try aggegator.append(
                    function: ENSContracts.ENSResolverFunctions.addr(contract: query.resolverAddress, _node: query.nameHash),
                    response: ENSContracts.ENSRegistryResponses.NameResolverResponse.self
                ) { result in
                    switch result {
                    case let .success(address):
                        registryOutput.intermediaryResponses[query.index] = NameResolveOutput(
                            ens: ens,
                            output: .resolved(address)
                        )
                    case let .failure(error):
                        registryOutput.intermediaryResponses[query.index] = NameResolveOutput(
                            ens: ens,
                            output: Self.output(from: error)
                        )
                    }
                }
            } catch {
                registryOutput.intermediaryResponses[query.index] = NameResolveOutput(
                    ens: ens,
                    output: Self.output(from: error)
                )
            }
        }

        private static func output<Value: Equatable>(from error: Error) -> ResolveOutput<Value> {
            guard let error = error as? Multicall.CallError else {
                return .couldNotBeResolved(.invalidInput)
            }

            switch error {
            case .contractFailure:
                return .couldNotBeResolved(.invalidInput)
            case let .couldNotDecodeResponse(error):
                if let specificError = error as? EthereumNameServiceError {
                    return .couldNotBeResolved(specificError)
                } else {
                    return .couldNotBeResolved(.invalidInput)
                }
            }
        }
    }
}
