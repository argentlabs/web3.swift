//
//  ENSMultiResolver.swift
//  web3swift
//
//  Created by David Rodrigues on 03/11/2020.
//  Copyright © 2020 Argent Labs Limited. All rights reserved.
//

import Foundation

extension EthereumNameService {

    @available(*, deprecated, message: "Prefer async alternative instead")
    public func resolve(
        addresses: [EthereumAddress],
        completion: @escaping (Result<[AddressResolveOutput], Web3Error>) -> Void
    ) {
        async {
            do {
                let result = try await resolve(addresses: addresses)
                completion(.success(result))
            } catch {
                completion(.failure(error as! Web3Error))
            }
        }
    }
    
    public func resolve(addresses: [EthereumAddress]) async throws -> [EthereumNameService.AddressResolveOutput] {
        
        return try await withCheckedThrowingContinuation({ continuation in
            MultiResolver(
                client: client,
                registryAddress: registryAddress
            ).resolve(addresses: addresses) { result in
                switch result {
                case .success(let output):
                    continuation.resume(returning: output)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        })
    }

    @available(*, deprecated, message: "Prefer async alternative instead")
    public func resolve(
        names: [String],
        completion: @escaping (Result<[NameResolveOutput], Web3Error>) -> Void
    ) {
        async {
            do {
                let result = try await resolve(names: names)
                completion(.success(result))
            } catch {
                completion(.failure(error as! Web3Error))
            }
        }
    }
        
    public func resolve(names: [String]) async throws -> [EthereumNameService.NameResolveOutput] {
        return try await withCheckedThrowingContinuation({ continuation in
            MultiResolver(
                client: client,
                registryAddress: registryAddress
            ).resolve(names: names) { result in
                switch result {
                case .success(let output):
                    continuation.resume(returning: output)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        })
    }
}

extension EthereumNameService {

    public enum ResolveOutput<Value: Equatable>: Equatable {
        case couldNotBeResolved(Web3Error)
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
                intermediaryResponses = Array(repeating: nil, count: expectedResponsesCount)
            }
        }

        private struct ResolverQuery {
            let index: Int
            let parameter: ENSRegistryResolverParameter
            let resolverAddress: EthereumAddress
            let nameHash: Data
        }

        let client: EthereumClientProtocol
        let registryAddress: EthereumAddress?
        let multicall: Multicall

        init(
            client: EthereumClientProtocol,
            registryAddress: EthereumAddress? = nil
        ) {
            self.client = client
            self.registryAddress = registryAddress
            self.multicall = Multicall(client: client)
        }

        func resolve(
            addresses: [EthereumAddress],
            completion: @escaping (Result<[AddressResolveOutput], Web3Error>) -> Void
        ) {
            let output = RegistryOutput<AddressResolveOutput>(expectedResponsesCount: addresses.count)

            resolveRegistry(
                parameters: addresses.map(ENSRegistryResolverParameter.address),
                handler: { index, parameter, result in
                    // TODO: Temporary solution
                    guard let address = parameter.address else { return }
                    switch result {
                    case .success(let resolverAddress):
                        output.queries.append(
                            ResolverQuery(
                                index: index,
                                parameter: parameter,
                                resolverAddress: resolverAddress,
                                nameHash: parameter.nameHash
                            )
                        )
                    case .failure(let error):
                        output.intermediaryResponses[index] = AddressResolveOutput(
                            address: address,
                            output: Self.output(from: error)
                        )
                    }
                }, completion: { result  in
                    switch result {
                    case .success:
                        Task(priority: .userInitiated) {
                            do {
                                let output = try await self.resolveQueries(registryOutput: output)
                                completion(.success(output))
                            } catch {
                                guard let error = error as? Web3Error else {
                                    completion(.failure(.unknownError))
                                    return
                                }
                                completion(.failure(error))
                            }
                        }
                    case .failure(let error):
                        completion(.failure(error))
                    }
                })
        }

        func resolve(
            names: [String],
            completion: @escaping (Result<[NameResolveOutput], Web3Error>) -> Void
        ) {
            let output = RegistryOutput<NameResolveOutput>(expectedResponsesCount: names.count)

            resolveRegistry(
                parameters: names.map(ENSRegistryResolverParameter.name),
                handler: { index, parameter, result in
                    // TODO: Temporary solution
                    guard let name = parameter.name else { return }
                    switch result {
                    case .success(let resolverAddress):
                        output.queries.append(
                            ResolverQuery(
                                index: index,
                                parameter: parameter,
                                resolverAddress: resolverAddress,
                                nameHash: parameter.nameHash
                            )
                        )
                    case .failure(let error):
                        output.intermediaryResponses[index] = NameResolveOutput(
                            ens: name,
                            output: Self.output(from: error)
                        )
                    }
                }, completion: { result  in
                    switch result {
                    case .success:
                        self.resolveQueries(registryOutput: output) { result in
                            switch result {
                            case .success(let output):
                                completion(.success(output))
                            case .failure:
                                completion(result)
                            }
                        }
                    case .failure(let error):
                        completion(.failure(error))
                    }
                })
        }

        private func resolveRegistry(
            parameters: [ENSRegistryResolverParameter],
            handler: @escaping (Int, ENSRegistryResolverParameter, Result<EthereumAddress, Web3Error>) -> Void,
            completion: @escaping (Result<Void, Web3Error>) -> Void
        ) {

            guard
                let network = client.network,
                let ensRegistryAddress = self.registryAddress ?? ENSContracts.registryAddress(for: network)
            else { return completion(.failure(.noNetwork)) }


            var aggegator = Multicall.Aggregator()

            do {
                try parameters.enumerated().forEach { index, parameter in

                    let function = ENSContracts.ENSRegistryFunctions.resolver(contract: ensRegistryAddress, parameter: parameter)

                    try aggegator.append(
                        function: function,
                        response: ENSContracts.ENSRegistryResponses.RegistryResponse.self
                    ) { result in handler(index, parameter, result) }
                }

                multicall.aggregate(calls: aggegator.calls) { result in
                    switch result {
                    case .success:
                        completion(.success(()))
                    case .failure:
                        completion(.failure(.noNetwork))
                    }
                }
            } catch {
                completion(.failure(.invalidInput))
            }
        }

        @available(*, deprecated, message: "Prefer async alternative instead")
        private func resolveQueries<ResolverOutput>(
            registryOutput: RegistryOutput<ResolverOutput>,
            completion: @escaping (Result<[ResolverOutput], Web3Error>) -> Void
        ) {
            async {
                do {
                    let result: [ResolverOutput] = try await resolveQueries(registryOutput: registryOutput)
                    completion(.success(result))
                } catch {
                    completion(.failure(error as! Web3Error))
                }
            }
        }
                
        private func resolveQueries<ResolverOutput>(registryOutput: RegistryOutput<ResolverOutput>) async throws -> [ResolverOutput] {
                        
            // TODO: Refactor to concurrent calls using async let result = ... await result
        
            var aggegator = Multicall.Aggregator()
            
            try registryOutput.queries.forEach { query in
                
                switch query.parameter {
                case .address(let address):
                    
                    guard let registryOutput1 = registryOutput as? RegistryOutput<AddressResolveOutput> else {
                        throw Web3Error.invalidInput
                    }
                            
                    resolveAddress(query, address: address, aggegator: &aggegator, registryOutput: registryOutput1)
                case .name(let name):
                    guard let registryOutput1 = registryOutput as? RegistryOutput<NameResolveOutput> else {
                        throw Web3Error.invalidInput
                    }
                    resolveName(query, ens: name, aggegator: &aggegator, registryOutput: registryOutput1)
                }
            }
            
            let result = try await multicall.aggregate(calls: aggegator.calls)
            return registryOutput.intermediaryResponses.compactMap { $0 }
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
                    case .success(let name):
                        registryOutput.intermediaryResponses[query.index] = AddressResolveOutput(
                            address: address,
                            output: .resolved(name)
                        )
                    case .failure(let error):
                        registryOutput.intermediaryResponses[query.index] = AddressResolveOutput(
                            address: address,
                            output: Self.output(from: error)
                        )
                    }
                }
            } catch let error {
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
                    case .success(let address):
                        registryOutput.intermediaryResponses[query.index] = NameResolveOutput(
                            ens: ens,
                            output: .resolved(address)
                        )
                    case .failure(let error):
                        registryOutput.intermediaryResponses[query.index] = NameResolveOutput(
                            ens: ens,
                            output: Self.output(from: error)
                        )
                    }
                }
            } catch let error {
                registryOutput.intermediaryResponses[query.index] = NameResolveOutput(
                    ens: ens,
                    output: Self.output(from: error)
                )
            }
        }

        private static func output<Value: Equatable>(from error: Error) -> ResolveOutput<Value> {
            guard let error = error as? Web3Error
            else { return .couldNotBeResolved(.invalidInput) }

            switch error {
            case .couldNotDecodeResponse(let error):
                guard let specificError = error else {
                    fallthrough
                }
                return .couldNotBeResolved(specificError)
            default:
                return .couldNotBeResolved(.invalidInput)
            }
        
        }
    }
}
