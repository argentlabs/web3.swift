//
//  Aes.swift
//  web3swift
//
//  Created by Julien Niset on 16/02/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation
import aes

class Aes128Util {
    var key: Data
    var iv: Data?
    
    init(key: Data, iv: Data? = nil){
        self.key = key
        self.iv = iv
    }
    
    func xcrypt(input: Data) -> Data {
        let ctx = UnsafeMutablePointer<AES_ctx>.allocate(capacity: 1)
        defer {
            ctx.deallocate()
        }
        
        let keyPtr = (self.key as NSData).bytes.assumingMemoryBound(to: UInt8.self)
        
        if let iv = self.iv {
            let ivPtr = (iv as NSData).bytes.assumingMemoryBound(to: UInt8.self)
            AES_init_ctx_iv(ctx, keyPtr, ivPtr)
        } else {
            AES_init_ctx(ctx, keyPtr)
        }

        let inputPtr = (input as NSData).bytes.assumingMemoryBound(to: UInt8.self)
        let length = input.count
        let outputPtr = UnsafeMutablePointer<UInt8>.allocate(capacity: length)
        defer {
            outputPtr.deallocate()
        }
        outputPtr.assign(from: inputPtr, count: length)

        AES_CTR_xcrypt_buffer(ctx, outputPtr, UInt32(length))

        return Data(bytes: outputPtr, count: length)
    }
}
