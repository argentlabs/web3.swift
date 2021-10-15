//
//  ENSRegistryResponses.swift
//  web3swift
//
//  Created by David Rodrigues on 30/10/2020.
//  Copyright © 2020 Argent Labs Limited. All rights reserved.
//

import Foundation

extension ENSContracts {
    enum ENSRegistryResponses {
        struct RegistryResponse: MulticallDecodableResponse {
            var value: EthereumAddress

            init?(data: String) throws {
                guard data != "0x" else {
                    throw Web3Error.ensUnknown
                }

                let idx = data.index(data.endIndex, offsetBy: -40)
                self.value = EthereumAddress(String(data[idx...]).web3.withHexPrefix)

                guard self.value != .zero else {
                    throw Web3Error.ensUnknown
                }
            }
        }

        struct AddressResolverResponse: ABIResponse, MulticallDecodableResponse {
            static var types: [ABIType.Type] { [String.self] }

            var value: String

            init?(values: [ABIDecoder.DecodedValue]) throws {
                self.value = try values[0].decoded()
            }
        }

        struct NameResolverResponse: ABIResponse, MulticallDecodableResponse {
            static var types: [ABIType.Type] { [EthereumAddress.self] }

            var value: EthereumAddress

            init?(values: [ABIDecoder.DecodedValue]) throws {
                self.value = try values[0].decoded()
            }
        }
    }
}
