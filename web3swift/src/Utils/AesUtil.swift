//
//  web3.swift
//  Copyright © Argent Labs Limited. All rights reserved.
//

import aes
import Foundation

class Aes128Util {
    var key: Data
    var iv: Data?

    init(key: Data, iv: Data? = nil) {
        self.key = key
        self.iv = iv
    }

    func xcrypt(input: Data) -> Data {
        var ctx = AES_ctx()

        // The pointers must not outlive the withUnsafeBytes scope that vends them, so the
        // context is initialised inside it. Bridging to NSData to grab .bytes instead leaves
        // the pointer dangling once the temporary is released, which corrupts the key and the
        // IV on platforms without an autorelease pool.
        key.withUnsafeBytes { keyBuffer in
            guard let keyPtr = keyBuffer.bindMemory(to: UInt8.self).baseAddress else {
                return
            }

            if let iv {
                iv.withUnsafeBytes { ivBuffer in
                    guard let ivPtr = ivBuffer.bindMemory(to: UInt8.self).baseAddress else {
                        return
                    }
                    AES_init_ctx_iv(&ctx, keyPtr, ivPtr)
                }
            } else {
                AES_init_ctx(&ctx, keyPtr)
            }
        }

        var output = input
        output.withUnsafeMutableBytes { outputBuffer in
            guard let outputPtr = outputBuffer.bindMemory(to: UInt8.self).baseAddress else {
                return
            }
            AES_CTR_xcrypt_buffer(&ctx, outputPtr, UInt32(outputBuffer.count))
        }

        return output
    }
}
