//
//  web3.swift
//  Copyright © Argent Labs Limited. All rights reserved.
//

import P256K
import Logging
import Foundation

public enum KeyUtilError: Error {
    case invalidContext
    case privateKeyInvalid
    case unknownError
    case signatureFailure
    case signatureParseFailure
    case badArguments
}

public class KeyUtil {
    private static var logger: Logger {
        Logger(label: "web3.swift.key-util")
    }

    public static func generatePrivateKeyData() -> Data? {
        Data.randomOfLength(32)
    }

    public static func generatePublicKey(from privateKey: Data) throws -> Data {
        let privateKey = try P256K.Recovery.PrivateKey(dataRepresentation: privateKey, format: .uncompressed)

        let publicKey = privateKey.publicKey.dataRepresentation
        let publicKeyLength = publicKey.count
        let finalPublicKey = publicKey.subdata(in: 1 ..< publicKeyLength)
        return finalPublicKey
    }

    public static func generateAddress(from publicKey: Data) -> EthereumAddress {
        let hash = publicKey.web3.keccak256
        let address = hash.subdata(in: 12 ..< hash.count)
        return EthereumAddress(address.web3.hexString)
    }

    public static func sign(message: Data, with privateKey: Data, hashing: Bool) throws -> Data {
        let privateKey = try P256K.Recovery.PrivateKey(dataRepresentation: privateKey)
        let msgData = hashing ? message.web3.keccak256 : message
        let digest = HashDigest(msgData.bytes)
        let signature = try privateKey.signature(for: digest)

        let compactSignature = try signature.compactRepresentation.signature
        let recoveryId = try signature.compactRepresentation.recoveryId

        var resultSignature = Data(compactSignature)
        let v = UInt8(recoveryId & 0xFF)
        resultSignature.append(v)
        return resultSignature
    }

    public static func recoverPublicKey(message: Data, signature: Data) throws -> String {
        if signature.count != 65 || message.count != 32 {
            throw KeyUtilError.badArguments
        }

        let serializedSignature = Data(signature[0 ..< 64])
        var recoveryId = Int32(signature[64])
        if recoveryId >= 27, recoveryId <= 30 {
            recoveryId -= 27
        } else if recoveryId >= 31, recoveryId <= 34 {
            recoveryId -= 31
        } else if recoveryId >= 35, recoveryId <= 38 {
            recoveryId -= 35
        }

        let digest = HashDigest(message.bytes)
        let publicKey = try P256K.Recovery.PublicKey(
            digest,
            signature: P256K.Recovery.ECDSASignature(compactRepresentation: serializedSignature, recoveryId: recoveryId),
            format: .uncompressed
        )

        return "0x\(publicKey.dataRepresentation[1...].web3.keccak256.web3.hexString.suffix(40))"
    }
}
