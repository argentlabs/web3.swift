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
    func resolve(address: EthereumAddress, completion: @escaping((Web3Error?, String?) -> Void)) -> Void
    func resolve(ens: String, completion: @escaping((Web3Error?, EthereumAddress?) -> Void)) -> Void
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
    public func resolve(address: EthereumAddress, completion: @escaping ((Web3Error?, String?) -> Void)) {
        async {
            do {
                let result = try await resolve(address: address)
                completion(nil, result)
            } catch {
                completion(error as? Web3Error ?? Web3Error.decodeIssue, nil)
            }
        }
    }
        
    public func resolve(address: EthereumAddress) async throws -> String {
        
        guard
            let network = client.network,
            let registryAddress1 = self.registryAddress ?? ENSContracts.registryAddress(for: network) else {
                throw Web3Error.noNetwork
            }
        
        let ensReverse = address.value.web3.noHexPrefix + ".addr.reverse"
        let nameHash1 = Self.nameHash(name: ensReverse)
        
        let function = ENSContracts.ENSRegistryFunctions.resolver(contract: registryAddress1,
                                                                  _node: nameHash1.web3.hexData ?? Data())
        let registryTransaction = try function.transaction()
        
        let resolverData = try await client.eth_call(registryTransaction, block: .latest)
        guard resolverData != "0x" else {
            throw Web3Error.ensUnknown
        }
        let idx = resolverData.index(resolverData.endIndex, offsetBy: -40)
        let resolverAddress = EthereumAddress(String(resolverData[idx...]).web3.withHexPrefix)
        
        let function1 = ENSContracts.ENSResolverFunctions.name(contract: resolverAddress,
                                                              _node: nameHash1.web3.hexData ?? Data())
        let addressTransaction = try function1.transaction()
        
        let data = try await client.eth_call(addressTransaction, block: .latest)
        guard data != "0x" else {
            throw Web3Error.ensUnknown
        }
        
        let decoded = try ABIDecoder.decodeData(data, types: [String.self])
        guard let ensHex: String = try decoded.first?.decoded() else {
            throw Web3Error.decodeIssue
        }
        return ensHex
    }
    
    @available(*, deprecated, message: "Prefer async alternative instead")
    public func resolve(ens: String, completion: @escaping ((Web3Error?, EthereumAddress?) -> Void)) {
        async {
            do {
                let result = try await resolve(ens: ens)
                completion(nil, result)
            } catch {
                completion(error as? Web3Error ?? Web3Error.decodeIssue, nil)
            }
        }
    }
        
    public func resolve(ens: String) async throws -> EthereumAddress {
        
        guard
            let network = client.network,
            let registryAddress1 = self.registryAddress ?? ENSContracts.registryAddress(for: network) else {
                throw Web3Error.noNetwork
            }
        let nameHash1 = Self.nameHash(name: ens)
        let function = ENSContracts.ENSRegistryFunctions.resolver(contract: registryAddress1,
                                                                  _node: nameHash1.web3.hexData ?? Data())
        let registryTransaction = try function.transaction()
        
        let resolverData = try await client.eth_call(registryTransaction, block: .latest)
        guard resolverData != "0x" else {
            throw Web3Error.ensUnknown
        }
        
        let idx = resolverData.index(resolverData.endIndex, offsetBy: -40)
        let resolverAddress = EthereumAddress(String(resolverData[idx...]).web3.withHexPrefix)
        
        let addressFunction = ENSContracts.ENSResolverFunctions.addr(contract: resolverAddress, _node: nameHash1.web3.hexData ?? Data())
        let addressTransaction = try addressFunction.transaction()
        
        let data = try await client.eth_call(addressTransaction, block: .latest)
        guard data != "0x" else {
            throw Web3Error.ensUnknown
        }
        
        let decoded = try ABIDecoder.decodeData(data, types: [EthereumAddress.self])
        guard let ensAddress: EthereumAddress = try decoded.first?.decoded() else {
            throw Web3Error.decodeIssue
        }
        return ensAddress
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
