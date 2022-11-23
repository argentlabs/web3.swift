//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import BigInt
import Foundation

extension Multicall {
    public enum Contract {

        static let goerliAddress: EthereumAddress = "0x77dCa2C955b15e9dE4dbBCf1246B4B85b651e50e"
        static let mainnetAddress: EthereumAddress = "0xF34D2Cb31175a51B23fb6e08cA06d7208FaD379F"

        public static func registryAddress(for network: EthereumNetwork) -> EthereumAddress? {
            switch network {
            case .mainnet:
                return Self.mainnetAddress
            case .goerli:
                return Self.goerliAddress
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
