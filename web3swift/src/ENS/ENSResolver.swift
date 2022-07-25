//
//  ENSResolver.swift
//  web3swift
//
//  Created by Miguel on 17/05/2022.
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation

class ENSResolver {

    let address: EthereumAddress
    let callResolution: CallResolution
    private (set) var supportsWildCard: Bool?
    
    private let client: EthereumClientProtocol

    init(
        address: EthereumAddress,
        client: EthereumClientProtocol,
        callResolution: CallResolution,
        supportsWildCard: Bool? = nil
    ) {
        self.address = address
        self.callResolution = callResolution
        self.client = client
        self.supportsWildCard = supportsWildCard
    }

    func resolve(
        name: String,
        supportingWildcard mustSupportWildCard: Bool
    ) async throws -> EthereumAddress {
        let wildcardResolution: Bool
        if let supportsWildCard = self.supportsWildCard {
            wildcardResolution = supportsWildCard
        } else {
            wildcardResolution = try await supportsWildcard()
        }
        self.supportsWildCard = wildcardResolution

        if mustSupportWildCard && !wildcardResolution {
            // Wildcard name resolution (ENSIP-10)
            throw EthereumNameServiceError.ensUnknown
        }

        if wildcardResolution {
            let response = try await ENSContracts.ENSOffchainResolverFunctions.resolve(
                contract: address,
                parameter: .name(name)
            ).call(
                withClient: client,
                responseType: ENSContracts.AddressAsDataResponse.self,
                resolution: callResolution
            )
            return response.value
        } else {
            let response = try await ENSContracts.ENSResolverFunctions.addr(
                contract: address,
                parameter: .name(name)
            ).call(
                withClient: client,
                responseType: ENSContracts.AddressResponse.self,
                resolution: callResolution
            )
            return response.value
        }
    }

    func resolve(
        address: EthereumAddress
    ) async throws -> String {
        let wildcardResolution: Bool
        if let supportsWildCard = self.supportsWildCard {
            wildcardResolution = supportsWildCard
        } else {
            wildcardResolution = try await supportsWildcard()
        }
        self.supportsWildCard = wildcardResolution

        if wildcardResolution {
            let response = try await ENSContracts.ENSOffchainResolverFunctions.resolve(
                contract: self.address,
                parameter: .address(address)
            ).call(
                withClient: client,
                responseType: ENSContracts.StringAsDataResponse.self,
                resolution: callResolution
            )
            return response.value
        } else {
            let response = try await ENSContracts.ENSResolverFunctions.name(
                contract: self.address,
                parameter: .address(address)
            ).call(
                withClient: client,
                responseType: ENSContracts.StringResponse.self,
                resolution: callResolution
            )

            if response.value.isEmpty {
                throw EthereumNameServiceError.ensUnknown
            }

            return response.value
        }
    }

    func supportsWildcard() async throws -> Bool {
        try await ERC165(client: client).supportsInterface(
            contract: address,
            id: ENSContracts.ENSOffchainResolverFunctions.interfaceId
        )
    }
}
