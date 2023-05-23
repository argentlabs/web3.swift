//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import BigInt
import Foundation

/// An object which will verify if a given `SiweMessage` and signature match with the EVM address provided
public class SiweVerifier {
    /// Errors thrown when verifing a given message agains a signature
    public enum Error: Swift.Error {
        /// The provided message is from a different network than the client's.
        case differentNetwork
        /// The provided message has a `notBefore` field set and the verification time is before that time
        case messageIsNotActiveYet
        /// The provided message has a `expirationTime` field set and the verification time is after or at that time
        case messageIsExpired
        /// Failed to fetch `utf8` data from the message string
        case invalidMessageData
        /// Failed to fetch the hex data from the signature
        case invalidSignature
    }

    private let client: EthereumRPCProtocol
    private let dateProvider: () -> Date

    public init(client: EthereumRPCProtocol, dateProvider: @escaping () -> Date = Date.init) {
        self.client = client
        self.dateProvider = dateProvider
    }

    /// Verifies if a given EIP-4361 string message was signed by the address in the message.
    /// - Parameters:
    ///   - message: the EIP-4361 string message
    ///   - signature: the hexadecimal string of the alleged signature, prefixed with `0x`
    /// - Returns: a `Bool` indicating if the pair message-signature is verified (whether or not the signature came from the address in the message)
    /// - Throws: any errors thrown from `SiweMessage.init(_:)` and `SiweVerifier.verify(message:against)`
    public final func verify(_ message: String, against signature: String) async throws -> Bool {
        try await verify(message: SiweMessage(message), against: signature)
    }

    /// Verifies if a given `SiweMessage` was signed by the address in the message.
    /// - Parameters:
    ///   - message: the message to be verified
    ///   - signature: the hexadecimal string of the alleged signature, prefixed with `0x`
    /// - Returns: a `Bool` indicating if the pair message-signature is verified (whether or not the signature came from the address in the message)
    /// - Throws: `SiweVerifier.Error` if message is not verifiable;
    ///           might throw `KeyUtilError` in case recovering the address that signed the message fails
    public func verify(message: SiweMessage, against signature: String) async throws -> Bool {
        let date = dateProvider()

        if let notBefore = message.notBefore {
            if date < notBefore {
                throw Error.messageIsNotActiveYet
            }
        }

        if let expirationTime = message.expirationTime {
            if date >= expirationTime {
                throw Error.messageIsExpired
            }
        }

        guard message.chainId == client.network?.intValue else {
            throw Error.differentNetwork
        }

        guard let messageData = "\(message)".data(using: .utf8) else {
            throw Error.invalidMessageData
        }
        let prefix = "\u{19}Ethereum Signed Message:\n\(String(messageData.count))"
        guard let prefixData = prefix.data(using: .ascii) else {
            assertionFailure("Etherem personal message signature prefix is not valid")
            throw Error.invalidMessageData
        }
        let messageHash = (prefixData + messageData).web3.keccak256

        guard let signatureData = signature.web3.hexData else {
            throw Error.invalidSignature
        }

        let address = EthereumAddress(try KeyUtil.recoverPublicKey(message: messageHash, signature: signatureData))
        if address.toChecksumAddress() == message.address {
            return true
        } else {
            let erc1271 = ERC1271(client: client)
            return try await erc1271.isValidSignature(
                contract: EthereumAddress(message.address),
                messageHash: messageHash,
                signature: signatureData
            )
        }
    }
}
