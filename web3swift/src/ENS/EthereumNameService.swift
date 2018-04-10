//
//  EthereumNameService.swift
//  web3swift
//
//  Created by Matt Marshall on 06/03/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation

protocol EthereumNameServiceProtocol {
    init(client: EthereumClientProtocol)
    func resolve(address: String, completion: @escaping((EthereumNameServiceError?, String?) -> Void)) -> Void
    func resolve(ens: String, completion: @escaping((EthereumNameServiceError?, String?) -> Void)) -> Void
}

enum EthereumNameServiceError: Error {
    case noNetwork
    case noResolver
    case ensUnknown
    case contractIssue
    case decodeIssue
}

class EthereumNameService: EthereumNameServiceProtocol {
    let client: EthereumClientProtocol
    
    required init(client: EthereumClientProtocol) {
        self.client = client
    }
    
    func resolve(address: String, completion: @escaping ((EthereumNameServiceError?, String?) -> Void)) {
        guard let network = client.network else {
            return completion(EthereumNameServiceError.noNetwork, nil)
        }
        
        let ensReverse = address.noHexPrefix + ".addr.reverse"
        guard let regContract = ENSRegistryContract(chainId: network.intValue), let registryTransaction = try? regContract.resolver(name: ensReverse) else {
            return completion(EthereumNameServiceError.contractIssue, nil)
        }

        client.eth_call(registryTransaction, block: .Latest, completion: { (error, resolverData) in
            guard let resolverData = resolverData else {
                return completion(EthereumNameServiceError.noResolver, nil)
            }
            
            let idx = resolverData.index(resolverData.endIndex, offsetBy: -40)
            let resolverAddress = String(resolverData[idx...]).withHexPrefix
            let nameHash = EthereumNameService.nameHash(name: ensReverse)
            
            guard let resContract = ENSResolverContract(chainId: network.intValue, address: resolverAddress), let addressTransaction = try? resContract.name(namehash: nameHash) else {
                return completion(EthereumNameServiceError.contractIssue, nil)
            }
            
            self.client.eth_call(addressTransaction, block: .Latest, completion: { (error, data) in
                guard let data = data, data != "0x" else {
                    return completion(EthereumNameServiceError.ensUnknown, nil)
                }
                if let ensHex = (try? ABIDecoder.decodeData(data, types: ["string"])[0]) as? String {
                    completion(nil, ensHex.stringValue)
                } else {
                    completion(EthereumNameServiceError.decodeIssue, nil)
                }
                
            })
        })
    }
    
    func resolve(ens: String, completion: @escaping ((EthereumNameServiceError?, String?) -> Void)) {
        
        guard let network = client.network else {
            return completion(EthereumNameServiceError.noNetwork, nil)
        }
        
        guard let regContract = ENSRegistryContract(chainId: network.intValue), let registryTransaction = try? regContract.resolver(name: ens) else {
            return completion(EthereumNameServiceError.contractIssue, nil)
        }
        
        client.eth_call(registryTransaction, block: .Latest, completion: { (error, resolverData) in
            guard let resolverData = resolverData else {
                return completion(EthereumNameServiceError.noResolver, nil)
            }
            
            let idx = resolverData.index(resolverData.endIndex, offsetBy: -40)
            let resolverAddress = String(resolverData[idx...]).withHexPrefix
            
            guard let resContract = ENSResolverContract(chainId: network.intValue, address: resolverAddress), let addressTransaction = try? resContract.address(name: ens) else {
                return completion(EthereumNameServiceError.contractIssue, nil)
            }
            
            self.client.eth_call(addressTransaction, block: .Latest, completion: { (error, data) in
                guard let data = data, data != "0x" else {
                    return completion(EthereumNameServiceError.ensUnknown, nil)
                }
                
                if let ensAddress = (try? ABIDecoder.decodeData(data, types: ["address"])[0]) as? String {
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
            node.append(label.keccak256)
            node = node.keccak256
        }
        return node.hexString
    }
    
}
