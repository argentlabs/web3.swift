//
//  ByteExtensions.swift
//  web3swift
//
//  Created by Matt Marshall on 13/03/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation
import BigInt

extension BigInt {
    var bytes: [UInt8] {
        let data: Data
        if self.sign == .plus {
            data = self.magnitude.serialize()
        } else {
            // Twos Complement
            let len = self.magnitude.serialize().count
            let maximum = BigUInt(1) << (len * 8)
            let twosComplement = maximum - self.magnitude
            data = twosComplement.serialize()
        }
        
        
        let bytes = data.bytes
        let lastIndex = bytes.count - 1
        let firstIndex = bytes.index(where: {$0 != 0x00}) ?? lastIndex
        
        return Array(bytes[firstIndex...lastIndex])
    }
    
    init(twosComplement data: Data) {
        let unsigned = BigUInt(data)
        self.init(BigInt(unsigned))
        if data[0] == 0xff {
            self.negate()
        }
    }
}

extension Data {
    var bytes: [UInt8] {
        var sigBytes = [UInt8](repeating: 0, count: self.count)
        self.copyBytes(to: &sigBytes, count: self.count)
        return sigBytes
    }
    
    var strippingZeroesFromBytes: Data {
        var bytes = self.bytes
        while bytes.first == 0 {
            bytes.removeFirst()
        }
        return Data.init(bytes: bytes)
    }
}

extension String {
    var bytes: [UInt8] {
        return [UInt8](self.utf8)
    }
    
    var bytesFromHex: [UInt8]? {
        let hex = self.noHexPrefix
        do {
            let byteArray = try HexUtil.byteArray(fromHex: hex)
            return byteArray
        } catch {
            return nil
        }
    }
    
    init(hexFromBytes bytes: [UInt8]) {
        self.init("0x" + bytes.map() { String(format: "%02x", $0) }.reduce("", +))
    }
}
