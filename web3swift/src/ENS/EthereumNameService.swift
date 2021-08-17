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

    @available(*, deprecated, message: "Prefer async alternative instead")
    public func resolve(address: EthereumAddress, completion: @escaping ((EthereumNameServiceError?, String?) -> Void)) {
        async {
            do {
                let result = try await resolve(address: address)
                completion(nil, result)
            } catch {
                completion(error as? EthereumNameServiceError ?? EthereumNameServiceError.decodeIssue, nil)
            }
        }
    }
        
    public func resolve(address: EthereumAddress) async throws -> String {
        
        guard
            let network = client.network,
            let registryAddress1 = self.registryAddress ?? ENSContracts.registryAddress(for: network) else {
                throw EthereumNameServiceError.noNetwork
            }
        
        let ensReverse = address.value.web3.noHexPrefix + ".addr.reverse"
        let nameHash1 = Self.nameHash(name: ensReverse)
        
        let function = ENSContracts.ENSRegistryFunctions.resolver(contract: registryAddress1,
                                                                  _node: nameHash1.web3.hexData ?? Data())
        let registryTransaction = try function.transaction()
        
        let resolverData = try await client.eth_call(registryTransaction, block: .latest)
        guard resolverData != "0x" else {
            throw EthereumNameServiceError.ensUnknown
        }
        let idx = resolverData.index(resolverData.endIndex, offsetBy: -40)
        let resolverAddress = EthereumAddress(String(resolverData[idx...]).web3.withHexPrefix)
        
        let function1 = ENSContracts.ENSResolverFunctions.name(contract: resolverAddress,
                                                              _node: nameHash1.web3.hexData ?? Data())
        let addressTransaction = try function1.transaction()
        
        let data = try await client.eth_call(addressTransaction, block: .latest)
        guard data != "0x" else {
            throw EthereumNameServiceError.ensUnknown
        }
        
        let decoded = try ABIDecoder.decodeData(data, types: [String.self])
        guard let ensHex: String = try decoded.first?.decoded() else {
            throw EthereumNameServiceError.decodeIssue
        }
        return ensHex
    }
    
    @available(*, deprecated, message: "Prefer async alternative instead")
    public func resolve(ens: String, completion: @escaping ((EthereumNameServiceError?, EthereumAddress?) -> Void)) {
        async {
            do {
                let result = try await resolve(ens: ens)
                completion(nil, result)
            } catch {
                completion(error as? EthereumNameServiceError ?? EthereumNameServiceError.decodeIssue, nil)
            }
        }
    }
        
    public func resolve(ens: String) async throws -> EthereumAddress {
        
        guard
            let network = client.network,
            let registryAddress1 = self.registryAddress ?? ENSContracts.registryAddress(for: network) else {
                throw EthereumNameServiceError.noNetwork
            }
        let nameHash1 = Self.nameHash(name: ens)
        let function = ENSContracts.ENSRegistryFunctions.resolver(contract: registryAddress1,
                                                                  _node: nameHash1.web3.hexData ?? Data())
        let registryTransaction = try function.transaction()
        
        let resolverData = try await client.eth_call(registryTransaction, block: .latest)
        guard resolverData != "0x" else {
            throw EthereumNameServiceError.ensUnknown
        }
        
        let idx = resolverData.index(resolverData.endIndex, offsetBy: -40)
        let resolverAddress = EthereumAddress(String(resolverData[idx...]).web3.withHexPrefix)
        
        let addressFunction = ENSContracts.ENSResolverFunctions.addr(contract: resolverAddress, _node: nameHash1.web3.hexData ?? Data())
        let addressTransaction = try addressFunction.transaction()
        
        let data = try await client.eth_call(addressTransaction, block: .latest)
        guard data != "0x" else {
            throw EthereumNameServiceError.ensUnknown
        }
        
        let decoded = try ABIDecoder.decodeData(data, types: [EthereumAddress.self])
        guard let ensAddress: EthereumAddress = try decoded.first?.decoded() else {
            throw EthereumNameServiceError.decodeIssue
        }
        return ensAddress
        
//        let ensAddress: EthereumAddress = try? (try? ABIDecoder.decodeData(data1, types: [EthereumAddress.self]))?.first?.decoded() {
//            continuation.resume(returning: (nil, ensAddress))
//        } else {
//            continuation.resume(returning: (EthereumNameServiceError.decodeIssue, nil))
//        }
//
//
//        return await withCheckedContinuation { continuation in
//            client.eth_call(registryTransaction, block: .latest, completion: { (error, resolverData) in
//                guard let resolverData1 = resolverData else {
//                    return continuation.resume(returning: (EthereumNameServiceError.noResolver, nil))
//                }
//
//                guard resolverData1 != "0x" else {
//                    return continuation.resume(returning: (EthereumNameServiceError.ensUnknown, nil))
//                }
//
//                let idx = resolverData1.index(resolverData1.endIndex, offsetBy: -40)
//                let resolverAddress = EthereumAddress(String(resolverData1[idx...]).web3.withHexPrefix)
//
//                let function = ENSContracts.ENSResolverFunctions.addr(contract: resolverAddress, _node: nameHash1.web3.hexData ?? Data())
//                guard let addressTransaction = try? function.transaction() else {
//                    continuation.resume(returning: (EthereumNameServiceError.invalidInput, nil))
//                    return
//                }
//                // till here
//                self.client.eth_call(addressTransaction, block: .latest, completion: { (error, data) in
//                    guard let data1 = data, data1 != "0x" else {
//                        return continuation.resume(returning: (EthereumNameServiceError.ensUnknown, nil))
//                    }
//
//                    if let ensAddress: EthereumAddress = try? (try? ABIDecoder.decodeData(data1, types: [EthereumAddress.self]))?.first?.decoded() {
//                        continuation.resume(returning: (nil, ensAddress))
//                    } else {
//                        continuation.resume(returning: (EthereumNameServiceError.decodeIssue, nil))
//                    }
//                })
//            })
//        }
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
