//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Logging
import secp256k1
import Foundation

enum KeyUtilError: Error {
    case invalidContext
    case privateKeyInvalid
    case unknownError
    case signatureFailure
    case signatureParseFailure
    case badArguments
}

class KeyUtil {
    private static var logger: Logger {
        Logger(label: "web3.swift.key-util")
    }

    static func generatePrivateKeyData() -> Data? {
        Data.randomOfLength(32)
    }

    static func generatePublicKey(from privateKey: Data) throws -> Data {
        guard let ctx = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN | SECP256K1_CONTEXT_VERIFY)) else {
            logger.warning("Failed to generate a public key: invalid context.")
            throw KeyUtilError.invalidContext
        }

        defer {
            secp256k1_context_destroy(ctx)
        }

        let privateKeyPtr = (privateKey as NSData).bytes.assumingMemoryBound(to: UInt8.self)
        guard secp256k1_ec_seckey_verify(ctx, privateKeyPtr) == 1 else {
            logger.warning("Failed to generate a public key: private key is not valid.")
            throw KeyUtilError.privateKeyInvalid
        }

        let publicKeyPtr = UnsafeMutablePointer<secp256k1_pubkey>.allocate(capacity: 1)
        defer {
            publicKeyPtr.deallocate()
        }
        guard secp256k1_ec_pubkey_create(ctx, publicKeyPtr, privateKeyPtr) == 1 else {
            logger.warning("Failed to generate a public key: public key could not be created.")
            throw KeyUtilError.unknownError
        }

        var publicKeyLength = 65
        let outputPtr = UnsafeMutablePointer<UInt8>.allocate(capacity: publicKeyLength)
        defer {
            outputPtr.deallocate()
        }
        secp256k1_ec_pubkey_serialize(ctx, outputPtr, &publicKeyLength, publicKeyPtr, UInt32(SECP256K1_EC_UNCOMPRESSED))

        let publicKey = Data(bytes: outputPtr, count: publicKeyLength).subdata(in: 1 ..< publicKeyLength)

        return publicKey
    }

    static func generateAddress(from publicKey: Data) -> EthereumAddress {
        let hash = publicKey.web3.keccak256
        let address = hash.subdata(in: 12 ..< hash.count)
        return EthereumAddress(address.web3.hexString)
    }

    static func sign(message: Data, with privateKey: Data, hashing: Bool) throws -> Data {
        guard let ctx = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN | SECP256K1_CONTEXT_VERIFY)) else {
            logger.warning("Failed to sign message: invalid context.")
            throw KeyUtilError.invalidContext
        }

        defer {
            secp256k1_context_destroy(ctx)
        }

        let msgData = hashing ? message.web3.keccak256 : message
        let msg = (msgData as NSData).bytes.assumingMemoryBound(to: UInt8.self)
        let privateKeyPtr = (privateKey as NSData).bytes.assumingMemoryBound(to: UInt8.self)
        let signaturePtr = UnsafeMutablePointer<secp256k1_ecdsa_recoverable_signature>.allocate(capacity: 1)
        defer {
            signaturePtr.deallocate()
        }
        guard secp256k1_ecdsa_sign_recoverable(ctx, signaturePtr, msg, privateKeyPtr, nil, nil) == 1 else {
            logger.warning("Failed to sign message: recoverable ECDSA signature creation failed.")
            throw KeyUtilError.signatureFailure
        }

        let outputPtr = UnsafeMutablePointer<UInt8>.allocate(capacity: 64)
        defer {
            outputPtr.deallocate()
        }
        var recid: Int32 = 0
        secp256k1_ecdsa_recoverable_signature_serialize_compact(ctx, outputPtr, &recid, signaturePtr)

        let outputWithRecidPtr = UnsafeMutablePointer<UInt8>.allocate(capacity: 65)
        defer {
            outputWithRecidPtr.deallocate()
        }
        outputWithRecidPtr.assign(from: outputPtr, count: 64)
        outputWithRecidPtr.advanced(by: 64).pointee = UInt8(recid)

        let signature = Data(bytes: outputWithRecidPtr, count: 65)

        return signature
    }

    static func recoverPublicKey(message: Data, signature: Data) throws -> String {
        if signature.count != 65 || message.count != 32 {
            throw KeyUtilError.badArguments
        }

        guard let ctx = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN | SECP256K1_CONTEXT_VERIFY)) else {
            logger.warning("Failed to sign message: invalid context.")
            throw KeyUtilError.invalidContext
        }
        defer { secp256k1_context_destroy(ctx) }

        // get recoverable signature
        let signaturePtr = UnsafeMutablePointer<secp256k1_ecdsa_recoverable_signature>.allocate(capacity: 1)
        defer { signaturePtr.deallocate() }

        let serializedSignature = Data(signature[0 ..< 64])
        var v = Int32(signature[64])
        if v >= 27, v <= 30 {
            v -= 27
        } else if v >= 31, v <= 34 {
            v -= 31
        } else if v >= 35, v <= 38 {
            v -= 35
        }

        try serializedSignature.withUnsafeBytes {
            guard secp256k1_ecdsa_recoverable_signature_parse_compact(ctx, signaturePtr, $0.bindMemory(to: UInt8.self).baseAddress!, v) == 1 else {
                logger.warning("Failed to parse signature: recoverable ECDSA signature parse failed.")
                throw KeyUtilError.signatureParseFailure
            }
        }
        let pubkey = UnsafeMutablePointer<secp256k1_pubkey>.allocate(capacity: 1)
        defer { pubkey.deallocate() }

        try message.withUnsafeBytes {
            guard secp256k1_ecdsa_recover(ctx, pubkey, signaturePtr, $0.bindMemory(to: UInt8.self).baseAddress!) == 1 else {
                throw KeyUtilError.signatureFailure
            }
        }
        var size = 65
        var rv = Data(count: size)
        rv.withUnsafeMutableBytes {
            secp256k1_ec_pubkey_serialize(ctx, $0.bindMemory(to: UInt8.self).baseAddress!, &size, pubkey, UInt32(SECP256K1_EC_UNCOMPRESSED))
        }
        return "0x\(rv[1...].web3.keccak256.web3.hexString.suffix(40))"
    }
}
