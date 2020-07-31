//
//  ENSContracts.swift
//  web3swift
//
//  Created by Matt Marshall on 13/03/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation
import BigInt

enum ENSContracts {
    static let RopstenAddress = EthereumAddress("0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e")
    static let MainnetAddress = EthereumAddress("0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e")
    
    static func registryAddress(for network: EthereumNetwork) -> EthereumAddress? {
        switch network {
        case .Ropsten:
            return ENSContracts.RopstenAddress
        case .Mainnet:
            return ENSContracts.MainnetAddress
        default:
            return nil
        }
    }
    
    enum ENSResolverFunctions {
        struct addr: ABIFunction {
            static let name = "addr"
            let gasPrice: BigUInt?
            let gasLimit: BigUInt?
            var contract: EthereumAddress
            let from: EthereumAddress?
            
            let _node: Data
            
            init(contract: EthereumAddress,
                 from: EthereumAddress? = nil,
                 gasPrice: BigUInt? = nil,
                 gasLimit: BigUInt? = nil,
                 _node: Data) {
                self.contract = contract
                self.from = from
                self.gasPrice = gasPrice
                self.gasLimit = gasLimit
                self._node = _node
            }
            
            public func encode(to encoder: ABIFunctionEncoder) throws {
                try encoder.encode(_node, staticSize: 32)
            }
        }
        
        struct name: ABIFunction {
            static let name = "name"
            let gasPrice: BigUInt?
            let gasLimit: BigUInt?
            var contract: EthereumAddress
            let from: EthereumAddress?
            
            let _node: Data
            
            init(contract: EthereumAddress,
                 from: EthereumAddress? = nil,
                 gasPrice: BigUInt? = nil,
                 gasLimit: BigUInt? = nil,
                 _node: Data) {
                self.contract = contract
                self.from = from
                self.gasPrice = gasPrice
                self.gasLimit = gasLimit
                self._node = _node
            }
            
            public func encode(to encoder: ABIFunctionEncoder) throws {
                try encoder.encode(_node, staticSize: 32)
            }
        }
    }
    
    enum ENSRegistryFunctions {
        struct resolver: ABIFunction {
            static let name = "resolver"
            let gasPrice: BigUInt?
            let gasLimit: BigUInt?
            var contract: EthereumAddress
            let from: EthereumAddress?
            
            let _node: Data
            
            init(contract: EthereumAddress,
                 from: EthereumAddress? = nil,
                 gasPrice: BigUInt? = nil,
                 gasLimit: BigUInt? = nil,
                 _node: Data) {
                self.contract = contract
                self.from = from
                self.gasPrice = gasPrice
                self.gasLimit = gasLimit
                self._node = _node
            }
            
            public func encode(to encoder: ABIFunctionEncoder) throws {
                try encoder.encode(_node, staticSize: 32)
            }
        }
        
        struct owner: ABIFunction {
            static let name = "owner"
            let gasPrice: BigUInt?
            let gasLimit: BigUInt?
            var contract: EthereumAddress
            let from: EthereumAddress?
            
            let _node: Data
            
            init(contract: EthereumAddress,
                 from: EthereumAddress? = nil,
                 gasPrice: BigUInt? = nil,
                 gasLimit: BigUInt? = nil,
                 _node: Data) {
                self.contract = contract
                self.from = from
                self.gasPrice = gasPrice
                self.gasLimit = gasLimit
                self._node = _node
            }
            
            public func encode(to encoder: ABIFunctionEncoder) throws {
                try encoder.encode(_node, staticSize: 32)
            }
        }
    }
}
