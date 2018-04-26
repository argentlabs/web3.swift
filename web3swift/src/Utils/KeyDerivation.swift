//
//  KeyDerivation.swift
//  web3swift
//
//  Created by Julien Niset on 20/06/2017.
//  Copyright © 2017 Argent Labs Limited. All rights reserved.
//

import Foundation
import CommonCrypto

enum KeyDerivationAlgorithm {
    case pbkdf2sha256
    case pbkdf2sha512
    
    func ccAlgorithm() -> CCAlgorithm {
        switch (self) {
        case .pbkdf2sha256:
            return CCPBKDFAlgorithm(kCCPRFHmacAlgSHA256)
        case .pbkdf2sha512:
            return CCPBKDFAlgorithm(kCCPRFHmacAlgSHA512)
        }
    }
    
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
    
    func deriveKey(key: String, salt: Data) -> Data? {
        
        let hash = self.algorithm.ccAlgorithm()
        let password = key
        let keyByteCount = self.dklen
        let rounds = self.round
        
        return self.pbkdf2(hash: hash, password: password, salt: salt, keyByteCount: keyByteCount, rounds: rounds)
        
    }
    
    func deriveKey(key: String, salt: String) -> Data? {
        
        let hash = self.algorithm.ccAlgorithm()
        let password = key
        guard let saltData = salt.data(using: .utf8) else { return nil }
        let keyByteCount = self.dklen
        let rounds = self.round
        
        return self.pbkdf2(hash: hash, password: password, salt: saltData, keyByteCount: keyByteCount, rounds: rounds)
        
    }
    
    private func pbkdf2(hash :CCPBKDFAlgorithm, password: String, salt: Data, keyByteCount: Int, rounds: Int) -> Data? {
        guard let passwordData = password.data(using:String.Encoding.utf8) else { return nil }
        var derivedKeyData = Data(repeating:0, count:keyByteCount)
        var mutableDerivedKeyData = derivedKeyData
        let derivationStatus = mutableDerivedKeyData.withUnsafeMutableBytes {derivedKeyBytes in
            salt.withUnsafeBytes { saltBytes in
                
                CCKeyDerivationPBKDF(
                    CCPBKDFAlgorithm(kCCPBKDF2),
                    password, passwordData.count,
                    saltBytes, salt.count,
                    hash,
                    UInt32(rounds),
                    derivedKeyBytes, derivedKeyData.count)
            }
        }
        
        derivedKeyData = mutableDerivedKeyData
        
        if (derivationStatus != 0) {
            print("Error: \(derivationStatus)")
            return nil;
        }
        
        return derivedKeyData
    }
    
}
