//
//  ENSContracts.swift
//  web3swift
//
//  Created by Matt Marshall on 13/03/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation
import BigInt

public enum ENSContracts {
    static let RopstenAddress = EthereumAddress("0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e")
    static let MainnetAddress = EthereumAddress("0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e")
    
    public static func registryAddress(for network: EthereumNetwork) -> EthereumAddress? {
        switch network {
        case .Ropsten:
            return ENSContracts.RopstenAddress
        case .Mainnet:
            return ENSContracts.MainnetAddress
        default:
            return nil
        }
    }
    
    public enum ENSResolverFunctions {
        public struct addr: ABIFunction {
            public static let name = "addr"
            public let gasPrice: BigUInt?
            public let gasLimit: BigUInt?
            public var contract: EthereumAddress
            public let from: EthereumAddress?
            
            public let _node: Data
            
            public init(contract: EthereumAddress,
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
        
        public struct name: ABIFunction {
            public static let name = "name"
            public let gasPrice: BigUInt?
            public let gasLimit: BigUInt?
            public var contract: EthereumAddress
            public let from: EthereumAddress?
            
            public let _node: Data
            
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

            public init(contract: EthereumAddress,
                        from: EthereumAddress? = nil,
                        gasPrice: BigUInt? = nil,
                        gasLimit: BigUInt? = nil,
                        query: EthereumAddress) {
                let ensReverse = query.value.web3.noHexPrefix + ".addr.reverse"
                let nameHash = ENSContracts.nameHash(name: ensReverse)

                self.init(
                    contract: contract,
                    from: from,
                    gasPrice: gasPrice,
                    gasLimit: gasLimit,
                    _node: nameHash.web3.hexData ?? Data()
                )
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
