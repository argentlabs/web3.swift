//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation

extension SiweMessage {

    /// Errors thrown when checking if a `SiweMessage` is valid or not
    public enum ValidationError: Swift.Error {
        /// The domain provided is not valid, should be a host name
        case invalidDomain
        /// The EVM address is invalid, should be `0x` prefixed and EIP-55 encoded (upper/lowercase encoded)
        case invalidAddress
        /// The version of the message is invalid
        case invalidVersion
        /// The chain id of the message is invalid
        case invalidChainId
        /// The nonce of the message is invalid
        case invalidNonce
        /// The request id of the message is invalid
        case invalidRequestId
    }

    func validate() throws {

        guard
            !domain.isEmpty,
            domain.matches(regex: "[^#?]*")
        else { throw ValidationError.invalidDomain }

        guard address.isEIP55Address else { throw ValidationError.invalidAddress }

        guard version == "1" else { throw ValidationError.invalidVersion }

        guard chainId > 0 else { throw ValidationError.invalidChainId }

        guard
            nonce.count >= 8,
            nonce.matches(regex: "[a-zA-Z0-9]{8,}")
        else { throw ValidationError.invalidNonce }

        if let requestId = requestId {
            guard
                !requestId.isEmpty,
                requestId.matches(regex: "[-._~!$&'()*+,;=:@%a-zA-Z0-9]*")
            else { throw ValidationError.invalidRequestId }
        }
    }
}

private extension String {

    func matches(regex: String) -> Bool {
        let match = range(of: regex, options: .regularExpression, range: startIndex ..< endIndex, locale: Locale(identifier: "en_US_POSIX"))
        return match == startIndex ..< endIndex
    }

    var isEIP55Address: Bool {
        let address = EthereumAddress(self)
        return self.compare(address.toChecksumAddress()) == .orderedSame
    }
}
