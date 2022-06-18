//
//  CryptoSwift
//
//  Copyright (C) 2014-2021 Marcin Krzyżanowski <marcin@krzyzanowskim.com>
//  This software is provided 'as-is', without any express or implied warranty.
//
//  In no event will the authors be held liable for any damages arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:
//
//  - The origin of this software must not be misrepresented; you must not claim that you wrote the original software. If you use this software in a product, an acknowledgment in the product documentation is required.
//  - Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
//  - This notice may not be removed or altered from any source or binary distribution.
//
public final class HMAC {
    public enum Error: Swift.Error {
        case authenticateError
        case invalidInput
    }

    public enum Variant {
        case sha256
        case sha512

        var digestLength: Int {
            switch self {
            case .sha256:
                return SHA2.Variant.sha256.digestLength
            case .sha512:
                return SHA2.Variant.sha512.digestLength
            }
        }

        func calculateHash(_ bytes: [UInt8]) -> [UInt8] {
            switch self {
            case .sha256:
                return SHA2(variant: .sha256).calculate(for: bytes)
            case .sha512:
                return SHA2(variant: .sha512).calculate(for: bytes)
            }
        }

        func blockSize() -> Int {
            switch self {
            case .sha256:
                return SHA2.Variant.sha256.blockSize
            case .sha512:
                return SHA2.Variant.sha512.blockSize
            }
        }
    }

    var key: [UInt8]
    let variant: Variant

    public init(key: [UInt8], variant: HMAC.Variant = .sha256) {
        self.variant = variant
        self.key = key

        if key.count > variant.blockSize() {
            let hash = variant.calculateHash(key)
            self.key = hash
        }

        if key.count < variant.blockSize() {
            self.key = ZeroPadding().add(to: key, blockSize: variant.blockSize())
        }
    }

    // MARK: Authenticator
    public func authenticate(_ bytes: [UInt8]) throws -> [UInt8] {
        var opad = [UInt8](repeating: 0x5c, count: variant.blockSize())
        for idx in self.key.indices {
            opad[idx] = self.key[idx] ^ opad[idx]
        }
        var ipad = [UInt8](repeating: 0x36, count: variant.blockSize())
        for idx in self.key.indices {
            ipad[idx] = self.key[idx] ^ ipad[idx]
        }

        let ipadAndMessageHash = self.variant.calculateHash(ipad + bytes)
        let result = self.variant.calculateHash(opad + ipadAndMessageHash)

        // return Array(result[0..<10]) // 80 bits
        return result
    }
}
