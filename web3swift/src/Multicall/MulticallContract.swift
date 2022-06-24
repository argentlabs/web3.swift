//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import BigInt
import Foundation

extension Multicall {
    public enum Contract {

        static let ropstenAddress = EthereumAddress("0x604D19Ba889A223693B0E78bC1269760B291b9Df")
        static let rinkebyAddress = EthereumAddress("0xF20A5837Eb2D9F1F7cdf9D635f3Bc68C47B8B8fF")
        static let mainnetAddress = EthereumAddress("0xF34D2Cb31175a51B23fb6e08cA06d7208FaD379F")

        public static func registryAddress(for network: EthereumNetwork) -> EthereumAddress? {
            switch network {
            case .ropsten:
                return Self.ropstenAddress
            case .rinkeby:
                return Self.rinkebyAddress
            case .mainnet:
                return Self.mainnetAddress
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

                public init(contract: EthereumAddress,
                            from: EthereumAddress? = nil,
                            gasPrice: BigUInt? = nil,
                            gasLimit: BigUInt? = nil,
                            calls: [Call]) {
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
        }
    }
}
