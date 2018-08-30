//
//  ENSResolverContract.swift
//  web3swift
//
//  Created by Matt Marshall on 13/03/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation

class ENSResolverContract: EthereumJSONContract {
    private var chainId: Int
    
    init?(chainId: Int, address: EthereumAddress) {
        self.chainId = chainId
        
        let json = ENSContracts.ResolverJson
        super.init(json: json, address: address)
    }
    
    func address(name: String) throws -> EthereumTransaction {
        let namehash = EthereumNameService.nameHash(name: name)
        return try self.address(namehash: namehash)
    }
    
    func address(namehash: String) throws -> EthereumTransaction {
        let dataStr = try self.data(function: "addr", args: [namehash])
        guard let data = Data(hex: dataStr) else { throw ABIError.invalidValue }
        return EthereumTransaction(to: self.address, data: data)
    }
    
    func name(address: String) throws -> EthereumTransaction {
        let ens = address.noHexPrefix + ".addr.reverse"
        let namehash = EthereumNameService.nameHash(name: ens)
        return try self.name(namehash: namehash)
    }
    
    func name(namehash: String) throws -> EthereumTransaction {
        let dataStr = try self.data(function: "name", args: [namehash])
        guard let data = Data(hex: dataStr) else { throw ABIError.invalidValue }
        return EthereumTransaction(to: self.address, data: data)
    }
}
