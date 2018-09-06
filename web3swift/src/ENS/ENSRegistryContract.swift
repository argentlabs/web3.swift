//
//  ENSRegistryContract.swift
//  web3swift
//
//  Created by Matt Marshall on 13/03/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation

class ENSRegistryContract: EthereumJSONContract {
    private var chainId: Int
    
    init?(chainId: Int, registryAddress: EthereumAddress?) {
        self.chainId = chainId
        
        let network = EthereumNetwork.fromString(String(chainId))
        
        let address: EthereumAddress
        if let registryAddress = registryAddress {
            address = registryAddress
        } else {
            switch network {
            case .Ropsten:
                address = ENSContracts.RopstenAddress
            case .Mainnet:
                address = ENSContracts.MainnetAddress
            default:
                return nil
            }
        }
        
        let json = ENSContracts.RegistryJson
        super.init(json: json, address: address)
    }

    func owner(name: String) throws -> EthereumTransaction {
        let namehash = EthereumNameService.nameHash(name: name)
        return try self.owner(namehash: namehash)
    }
    
    func owner(namehash: String) throws -> EthereumTransaction {
        let data = try self.data(function: "owner", args: [namehash])
        return EthereumTransaction(to: self.address, data: data)
    }
    
    func resolver(name: String) throws -> EthereumTransaction {
        let namehash = EthereumNameService.nameHash(name: name)
        return try self.resolver(namehash: namehash)
    }
    
    func resolver(namehash: String) throws -> EthereumTransaction {
        let data = try self.data(function: "resolver", args: [namehash])
        return EthereumTransaction(to: self.address, data: data)
    }
}
