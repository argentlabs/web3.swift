//
//  KeyDerivation.swift
//  web3swift
//
//  Created by Julien Niset on 20/06/2017.
//  Copyright © 2017 Argent Labs Limited. All rights reserved.
//

import Foundation
#if canImport(CommonCrypto)
import CommonCrypto
#endif
#if !COCOAPODS
import CryptoSwift
#endif

enum KeyDerivationAlgorithm {
    case pbkdf2sha256
    case pbkdf2sha512

    #if canImport(CommonCrypto)
    func ccAlgorithm() -> CCAlgorithm {
        switch (self) {
        case .pbkdf2sha256:
            return CCPBKDFAlgorithm(kCCPRFHmacAlgSHA256)
        case .pbkdf2sha512:
            return CCPBKDFAlgorithm(kCCPRFHmacAlgSHA512)
        }
    }
    #endif

    func function() -> String {
        switch (self) {
        case .pbkdf2sha256:
            return "pbkdf2"
        case .pbkdf2sha512:
            return "pbkdf2"
        }
    }
    
    func hash() -> String {
        switch (self) {
        case .pbkdf2sha256:
            return "hmac-sha256"
        case .pbkdf2sha512:
            return "hmac-sha512"
        }
    }

    fileprivate func hmacVariant() -> HMAC.Variant {
        switch (self) {
        case .pbkdf2sha256:
            return .sha256
        case .pbkdf2sha512:
            return .sha512
        }
    }
}

class KeyDerivator {
    
    var algorithm: KeyDerivationAlgorithm
    var dklen: Int
    var round: Int
    
    init(algorithm: KeyDerivationAlgorithm, dklen: Int, round: Int) {
        self.algorithm = algorithm
        self.dklen = dklen
        self.round = round
    }
    
    func deriveKey(key: String, salt: Data, forceCryptoSwiftImplementation: Bool = false) -> Data? {

        let password = key
        let keyByteCount = self.dklen
        let rounds = self.round

        // This is done so we can test this implementation on a macOS setup
        if forceCryptoSwiftImplementation {
            return self.pbkdf2(variant: algorithm.hmacVariant(), password: password, salt: salt, keyByteCount: keyByteCount, rounds: rounds)
        }

        #if canImport(CommonCrypto)
        return self.pbkdf2(hash: algorithm.ccAlgorithm(), password: password, salt: salt, keyByteCount: keyByteCount, rounds: rounds)
        #else
        return self.pbkdf2(variant: algorithm.hmacVariant(), password: password, salt: salt, keyByteCount: keyByteCount, rounds: rounds)
        #endif
    }
    
    func deriveKey(key: String, salt: String, forceCryptoSwiftImplementation: Bool = false) -> Data? {

        let password = key
        guard let saltData = salt.data(using: .utf8) else { return nil }
        let keyByteCount = self.dklen
        let rounds = self.round

        // This is done so we can test this implementation on a macOS setup
        if forceCryptoSwiftImplementation {
            return self.pbkdf2(variant: algorithm.hmacVariant(), password: password, salt: saltData, keyByteCount: keyByteCount, rounds: rounds)
        }

        #if canImport(CommonCrypto)
        return self.pbkdf2(hash: algorithm.ccAlgorithm(), password: password, salt: saltData, keyByteCount: keyByteCount, rounds: rounds)
        #else
        return self.pbkdf2(variant: algorithm.hmacVariant(), password: password, salt: saltData, keyByteCount: keyByteCount, rounds: rounds)
        #endif

    }

    #if canImport(CommonCrypto)
    private func pbkdf2(hash :CCPBKDFAlgorithm, password: String, salt: Data, keyByteCount: Int, rounds: Int) -> Data? {
        guard let passwordData = password.data(using:String.Encoding.utf8) else { return nil }
        var derivedKeyData = [UInt8](repeating: 0, count: keyByteCount)
        var saltData = salt.web3.bytes
        let derivationStatus = CCKeyDerivationPBKDF(
            CCPBKDFAlgorithm(kCCPBKDF2),
            password,
            passwordData.count,
            &saltData,
            saltData.count,
            hash,
            UInt32(rounds),
            &derivedKeyData,
            derivedKeyData.count)

        if derivationStatus != 0 {
            print("Error: \(derivationStatus)")
            return nil;
        }
        return Data(derivedKeyData)
    }
    #endif
    
    private func pbkdf2(variant: HMAC.Variant, password: String, salt: Data, keyByteCount: Int, rounds: Int) -> Data? {

        guard let passwordData = password.data(using:String.Encoding.utf8) else { return nil }

        let derivedKey = try? PBKDF2(
            password: [UInt8](passwordData),
            salt: [UInt8](salt),
            iterations: rounds,
            keyLength: keyByteCount,
            variant: variant
        ).calculate()

        return derivedKey.map { Data($0) }
    }
    
}
