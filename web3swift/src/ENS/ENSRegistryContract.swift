//
//  ENSRegistryContract.swift
//  web3swift
//
//  Created by Matt Marshall on 13/03/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation

class ENSRegistryContract: EthereumContract {
    private var chainId: Int
    
    init?(chainId: Int) {
        self.chainId = chainId
        
        let network = EthereumNetwork.fromString(String(chainId))
        let address: String
        switch network {
        case .Ropsten:
            address = ENSContracts.RopstenAddress
        case .Mainnet:
            address = ENSContracts.MainnetAddress
        default:
            return nil
        }
        
        let json = ENSContracts.RegistryJson
        super.init(json: json, address: address)
    }

    func owner(name: String) throws -> EthereumTransaction {
        let namehash = EthereumNameService.nameHash(name: name)
        return try self.owner(namehash: namehash)
    }
    
    func owner(namehash: String) throws -> EthereumTransaction {
        let dataStr = try self.data(function: "owner", args: [namehash])
        guard let data = Data(hex: dataStr) else { throw EthereumContractError.unknownError }
        return EthereumTransaction(to: self.address, data: data, chainId: self.chainId)
    }
    
    func resolver(name: String) throws -> EthereumTransaction {
        let namehash = EthereumNameService.nameHash(name: name)
        return try self.resolver(namehash: namehash)
    }
    
    func resolver(namehash: String) throws -> EthereumTransaction {
        let dataStr = try self.data(function: "resolver", args: [namehash])
        guard let data = Data(hex: dataStr) else { throw EthereumContractError.unknownError }
        return EthereumTransaction(to: self.address, data: data, chainId: self.chainId)
    }
}
