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

extension EthereumNameService {

    public func resolve(
        addresses: [EthereumAddress],
        completion: @escaping (Result<[ResolveOutput], EthereumNameServiceError>) -> Void
    ) {
        MultiResolver(
            client: client,
            registryAddress: registryAddress,
            addresses: addresses,
            completion: completion
        ).resolve()
    }

    public struct ResolveOutput: Equatable {
        public let address: EthereumAddress
        public let output: Output

        public enum Output: Equatable {
            case couldNotBeResolved(EthereumNameServiceError)
            case resolved(name: String)
        }
    }

    private class MultiResolver {

        private struct ResolverQuery {
            let index: Int
            let address: EthereumAddress
            let resolverAddress: EthereumAddress
            let nameHash: Data
        }

        let client: EthereumClientProtocol
        let registryAddress: EthereumAddress?
        let addresses: [EthereumAddress]
        let multicall: Multicall
        let completion: (Result<[ResolveOutput], EthereumNameServiceError>) -> Void

        init(
            client: EthereumClientProtocol,
            registryAddress: EthereumAddress? = nil,
            addresses: [EthereumAddress],
            completion: @escaping (Result<[ResolveOutput], EthereumNameServiceError>) -> Void
        ) {
            self.client = client
            self.registryAddress = registryAddress
            self.addresses = addresses
            self.completion = completion
            self.multicall = Multicall(client: client)
        }

        func resolve() {
            resolveRegistry { result in
                switch result {
                case .success(let registryOutput):
                    self.resolveQueries(registryOutput: registryOutput) { result in
                        switch result {
                        case .success(let output):
                            self.completion(.success(output))
                        case .failure:
                            self.completion(result)
                        }
                    }
                case .failure(let error):
                    self.completion(.failure(error))
                }
            }
        }

        private struct RegistryOutput {
            var queries: [ResolverQuery] = []
            var intermediaryResponses: [ResolveOutput?]

            init(expectedResponsesCount: Int) {
                intermediaryResponses = Array(repeating: nil, count: expectedResponsesCount)
            }
        }

        private func resolveRegistry(
            completion: @escaping (Result<RegistryOutput, EthereumNameServiceError>) -> Void
        ) {

            guard
                let network = client.network,
                let ensRegistryAddress = self.registryAddress ?? ENSContracts.registryAddress(for: network)
                else { return completion(.failure(.noNetwork)) }


            var aggegator = Multicall.Aggregator()

            var output = RegistryOutput(expectedResponsesCount: addresses.count)

            do {
                try addresses.enumerated().forEach { index, address in

                    let function = ENSContracts.ENSRegistryFunctions.resolver(contract: ensRegistryAddress, query: address)

                    try aggegator.append(
                        function: function,
                        response: ENSContracts.ENSRegistryResponses.RegistryResponse.self
                    ) { result in
                        switch result {
                        case .success(let resolverAddress):
                            output.queries.append(
                                ResolverQuery(
                                    index: index,
                                    address: address,
                                    resolverAddress: resolverAddress,
                                    nameHash: function._node
                                )
                            )
                        case .failure(let error):
                            output.intermediaryResponses[index] = ResolveOutput(
                                address: address,
                                output: Self.output(from: error)
                            )
                        }
                    }
                }

                multicall.aggregate(calls: aggegator.calls) { result in
                    switch result {
                    case .success:
                        completion(.success(output))
                    case .failure:
                        completion(.failure(.noNetwork))
                    }
                }
            } catch {
                completion(.failure(.invalidInput))
            }
        }

        private func resolveQueries(
            registryOutput: RegistryOutput,
            completion: @escaping (Result<[ResolveOutput], EthereumNameServiceError>) -> Void
        ) {
            var aggegator = Multicall.Aggregator()

            var registryOutput = registryOutput

            registryOutput.queries.forEach { query in
                do {
                    try aggegator.append(
                        function: ENSContracts.ENSResolverFunctions.name(contract: query.resolverAddress, _node: query.nameHash),
                        response: ENSContracts.ENSRegistryResponses.ResolverResponse.self
                    ) { result in
                        switch result {
                        case .success(let name):
                            registryOutput.intermediaryResponses[query.index] = ResolveOutput(
                                address: query.address,
                                output: .resolved(name: name)
                            )
                        case .failure(let error):
                            registryOutput.intermediaryResponses[query.index] = ResolveOutput(
                                address: query.address,
                                output: Self.output(from: error)
                            )
                        }
                    }
                } catch let error {
                    registryOutput.intermediaryResponses[query.index] = ResolveOutput(
                        address: query.address,
                        output: Self.output(from: error)
                    )
                }
            }

            multicall.aggregate(calls: aggegator.calls) { [weak self] result in
                switch result {
                case .success:
                    self?.completion(.success(registryOutput.intermediaryResponses.compactMap { $0 }))
                case .failure:
                    self?.completion(.failure(.noNetwork))
                }
            }
        }

        private static func output(from error: Error) -> ResolveOutput.Output {
            guard let error = error as? Multicall.CallError
            else { return .couldNotBeResolved(.invalidInput) }

            switch error {
            case .contractFailure:
                return .couldNotBeResolved(.invalidInput)
            case .couldNotDecodeResponse(let error):
                if let specificError = error as? EthereumNameServiceError {
                    return .couldNotBeResolved(specificError)
                } else {
                    return .couldNotBeResolved(.invalidInput)
                }
            }
        }
    }
}
