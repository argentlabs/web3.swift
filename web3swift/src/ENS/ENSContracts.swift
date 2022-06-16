//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation
import BigInt

public typealias ENSRegistryResolverParameter = ENSContracts.ResolveParameter

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

    public enum ResolveParameter {
        case address(EthereumAddress)
        case name(String)

        var nameHash: Data {
            let nameHash: String
            switch self {
            case .address(let address):
                nameHash = ENSContracts.nameHash(
                    name: address.value.web3.noHexPrefix + ".addr.reverse"
                )
            case .name(let ens):
                nameHash = ENSContracts.nameHash(name: ens)
            }
            return nameHash.web3.hexData ?? Data()
        }

        var dnsEncoded: Data {
            switch self {
            case .address(let address):
                return ENSContracts.dnsEncode(
                    name: address.value.web3.noHexPrefix + ".addr.reverse"
                )
            case .name(let name):
                return ENSContracts.dnsEncode(name: name)
            }
        }

        var name: String? {
            switch self {
            case .name(let ens):
                return ens
            case .address:
                return nil
            }
        }

        var address: EthereumAddress? {
            switch self {
            case .address(let address):
                return address
            case .name:
                return nil
            }
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
            
            public init(
                contract: EthereumAddress,
                from: EthereumAddress? = nil,
                gasPrice: BigUInt? = nil,
                gasLimit: BigUInt? = nil,
                _node: Data
            ) {
                self.contract = contract
                self.from = from
                self.gasPrice = gasPrice
                self.gasLimit = gasLimit
                self._node = _node
            }

            public init(
                contract: EthereumAddress,
                from: EthereumAddress? = nil,
                gasPrice: BigUInt? = nil,
                gasLimit: BigUInt? = nil,
                parameter: ENSRegistryResolverParameter
            ) {
                self.contract = contract
                self.from = from
                self.gasPrice = gasPrice
                self.gasLimit = gasLimit
                self._node = parameter.nameHash
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
            
            init(
                contract: EthereumAddress,
                 from: EthereumAddress? = nil,
                 gasPrice: BigUInt? = nil,
                 gasLimit: BigUInt? = nil,
                 _node: Data
            ) {
                self.contract = contract
                self.from = from
                self.gasPrice = gasPrice
                self.gasLimit = gasLimit
                self._node = _node
            }

            public init(
                contract: EthereumAddress,
                from: EthereumAddress? = nil,
                gasPrice: BigUInt? = nil,
                gasLimit: BigUInt? = nil,
                parameter: ENSRegistryResolverParameter
            ) {
                self.contract = contract
                self.from = from
                self.gasPrice = gasPrice
                self.gasLimit = gasLimit
                self._node = parameter.nameHash
            }
            
            public func encode(to encoder: ABIFunctionEncoder) throws {
                try encoder.encode(_node, staticSize: 32)
            }
        }
    }

    public enum ENSOffchainResolverFunctions {
        public static var interfaceId: Data {
            return "0x9061b923".web3.hexData!
        }

        public struct resolve: ABIFunction {
            public static var name: String = "resolve"
            public let gasPrice: BigUInt?
            public let gasLimit: BigUInt?
            public var contract: EthereumAddress
            public let from: EthereumAddress?

            public let name: Data
            public let data: Data

            public init(
                contract: EthereumAddress,
                from: EthereumAddress? = nil,
                gasPrice: BigUInt? = nil,
                gasLimit: BigUInt? = nil,
                name: Data,
                data: Data
            ) {
                self.contract = contract
                self.from = from
                self.gasPrice = gasPrice
                self.gasLimit = gasLimit
                self.name = name
                self.data = data
            }

            public init(
                contract: EthereumAddress,
                from: EthereumAddress? = nil,
                gasPrice: BigUInt? = nil,
                gasLimit: BigUInt? = nil,
                parameter: ENSRegistryResolverParameter
            ) {
                self.contract = contract
                self.from = from
                self.gasPrice = gasPrice
                self.gasLimit = gasLimit
                self.name = parameter.dnsEncoded
                switch parameter {
                case .address:
                    self.data = try! ENSResolverFunctions.name(
                        contract: contract,
                        from: from,
                        gasPrice: gasPrice,
                        gasLimit: gasLimit,
                        parameter: parameter
                    ).transaction().data!
                case .name:
                    self.data = try! ENSResolverFunctions.addr(
                        contract: contract,
                        from: from,
                        gasPrice: gasPrice,
                        gasLimit: gasLimit,
                        parameter: parameter
                    ).transaction().data!
                }
            }

            public func encode(to encoder: ABIFunctionEncoder) throws {
                try encoder.encode(name)
                try encoder.encode(data)
            }
        }
    }
    
    public enum ENSRegistryFunctions {
        public struct resolver: ABIFunction {
            public static let name = "resolver"
            public let gasPrice: BigUInt?
            public let gasLimit: BigUInt?
            public var contract: EthereumAddress
            public let from: EthereumAddress?
            
            let _node: Data
            
            init(
                contract: EthereumAddress,
                from: EthereumAddress? = nil,
                gasPrice: BigUInt? = nil,
                gasLimit: BigUInt? = nil,
                _node: Data
            ) {
                self.contract = contract
                self.from = from
                self.gasPrice = gasPrice
                self.gasLimit = gasLimit
                self._node = _node
            }

            public init(
                contract: EthereumAddress,
                from: EthereumAddress? = nil,
                gasPrice: BigUInt? = nil,
                gasLimit: BigUInt? = nil,
                parameter: ResolveParameter
            ) {
                self.init(
                    contract: contract,
                    from: from,
                    gasPrice: gasPrice,
                    gasLimit: gasLimit,
                    _node: parameter.nameHash
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
            
            init(
                contract: EthereumAddress,
                from: EthereumAddress? = nil,
                gasPrice: BigUInt? = nil,
                gasLimit: BigUInt? = nil,
                _node: Data
            ) {
                self.contract = contract
                self.from = from
                self.gasPrice = gasPrice
                self.gasLimit = gasLimit
                self._node = _node
            }

            public init(
                contract: EthereumAddress,
                from: EthereumAddress? = nil,
                gasPrice: BigUInt? = nil,
                gasLimit: BigUInt? = nil,
                parameter: ENSRegistryResolverParameter
            ) {
                self.contract = contract
                self.from = from
                self.gasPrice = gasPrice
                self.gasLimit = gasLimit
                self._node = parameter.nameHash
            }
            
            public func encode(to encoder: ABIFunctionEncoder) throws {
                try encoder.encode(_node, staticSize: 32)
            }
        }
    }

    public struct AddressResponse: ABIResponse, MulticallDecodableResponse {
        public static var types: [ABIType.Type] = [ EthereumAddress.self ]
        public let value: EthereumAddress

        public init?(values: [ABIDecoder.DecodedValue]) throws {
            self.value = try values[0].decoded()
        }
    }

    public struct StringResponse: ABIResponse, MulticallDecodableResponse {
        public static var types: [ABIType.Type] = [ String.self ]
        public let value: String

        public init?(values: [ABIDecoder.DecodedValue]) throws {
            self.value = try values[0].decoded()
        }
    }

    public struct AddressAsDataResponse: ABIResponse, MulticallDecodableResponse {
        public static var types: [ABIType.Type] = [ Data.self ]
        public let value: EthereumAddress

        public init?(values: [ABIDecoder.DecodedValue]) throws {
            let data: Data = try values[0].decoded()
            self.value = try ABIDecoder.decodeData(data.web3.hexString, types: [EthereumAddress.self])[0].decoded()
        }
    }

    public struct StringAsDataResponse: ABIResponse, MulticallDecodableResponse {
        public static var types: [ABIType.Type] = [ Data.self ]
        public let value: String

        public init?(values: [ABIDecoder.DecodedValue]) throws {
            let data: Data = try values[0].decoded()
            self.value = try ABIDecoder.decodeData(data.web3.hexString, types: [String.self])[0].decoded()
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

    static func dnsEncode(name: String) -> Data {
        let encoded = name.split(separator: ".")
            .compactMap { part -> [UInt8]? in
                guard part.count < 63 else { // Max byte size
                    return nil
                }
                guard var utf8 = "_\(part)".data(using: .utf8)?.web3.bytes else {
                    return nil
                }
                utf8[0] = UInt8(utf8.count - 1)
                return utf8
            }
            .flatMap { $0 }
        return Data(encoded + [0x00])
    }
}
