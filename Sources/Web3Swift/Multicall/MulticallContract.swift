//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import BigInt
import Foundation

extension Multicall {
    public enum Contract {
        public enum Registry {
            static let sepolia: EthereumAddress = "0x25Eef291876194AeFAd0D60Dff89e268b90754Bb"
            static let mainnet: EthereumAddress = "0xF34D2Cb31175a51B23fb6e08cA06d7208FaD379F"
        }

        public enum Multicall2 {
            static let mainnet: EthereumAddress = "0x5ba1e12693dc8f9c48aad8770482f4739beed696"
            static let sepolia: EthereumAddress = "0x55344B7242EB48e332aaccec3e0cFbE553Be88B5"
        }

        public static func registryAddress(for network: EthereumNetwork) -> EthereumAddress? {
            switch network {
            case .mainnet:
                return Multicall.Contract.Registry.mainnet
            case .sepolia:
                return Multicall.Contract.Registry.sepolia
            default:
                return nil
            }
        }

        public static func multicall2Address(for network: EthereumNetwork) -> EthereumAddress? {
            switch network {
            case .mainnet:
                return Multicall.Contract.Multicall2.mainnet
            case .sepolia:
                return Multicall.Contract.Multicall2.sepolia
            default:
                return nil
            }
        }

        public enum Functions {
            public struct aggregate: ABIFunction {
                public static let name = "aggregate"
                public let gasPrice: BigUInt?
                public let gasLimit: BigUInt?
                public var contract: EthereumAddress
                public let from: EthereumAddress?
                public let calls: [Call]

                public init(
                    contract: EthereumAddress,
                    from: EthereumAddress? = nil,
                    gasPrice: BigUInt? = nil,
                    gasLimit: BigUInt? = nil,
                    calls: [Call]
                ) {
                    self.contract = contract
                    self.from = from
                    self.gasPrice = gasPrice
                    self.gasLimit = gasLimit
                    self.calls = calls
                }

                public func encode(to encoder: ABIFunctionEncoder) throws {
                    try encoder.encode(calls)
                }
            }

            public struct tryAggregate: ABIFunction {
                public static let name = "tryAggregate"
                public let gasPrice: BigUInt?
                public let gasLimit: BigUInt?
                public var contract: EthereumAddress
                public let from: EthereumAddress?
                public let requireSuccess: Bool
                public let calls: [Call]

                public init(
                    contract: EthereumAddress,
                    from: EthereumAddress? = nil,
                    gasPrice: BigUInt? = nil,
                    gasLimit: BigUInt? = nil,
                    requireSuccess: Bool,
                    calls: [Call]
                ) {
                    self.contract = contract
                    self.gasPrice = gasPrice
                    self.gasLimit = gasLimit
                    self.from = from
                    self.requireSuccess = requireSuccess
                    self.calls = calls
                }

                public func encode(to encoder: ABIFunctionEncoder) throws {
                    try encoder.encode(requireSuccess)
                    try encoder.encode(calls)
                }
            }
        }
    }
}
