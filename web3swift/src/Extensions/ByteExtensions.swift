//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import BigInt
import Foundation

public extension Web3Extensions where Base == BigUInt {
    var bytes: [UInt8] {
        let data = base.magnitude.serialize()
        let bytes = data.web3.bytes
        let lastIndex = bytes.count - 1
        let firstIndex = bytes.firstIndex(where: {$0 != 0x00}) ?? lastIndex

        if lastIndex < 0 {
            return Array([0])
        }

        return Array(bytes[firstIndex...lastIndex])
    }
}

extension BigInt {
    init(twosComplement data: Data) {
        guard data.count > 1 else {
            self.init(0)
            return
        }

        let isNegative = data[0] & 0x80 == 0x80
        guard isNegative else {
            self = BigInt(BigUInt(data))
            return
        }

        let bytesLength = data.count
        let signBit = BigUInt(2).power(bytesLength * 8) / 2
        let signValue = isNegative ? signBit : 0
        let rest = data.enumerated().map { index, value in
            index == 0 ? value & 0x7f : value
        }

        self = BigInt(signValue - BigUInt(Data(rest)))
        negate()
    }
}

public extension Web3Extensions where Base == BigInt {
    var bytes: [UInt8] {
        let data: Data
        if base.sign == .plus {
            data = base.magnitude.serialize()
        } else {
            let len = base.magnitude.serialize().count + 1
            let maximum = BigUInt(2).power(len * 8)
            let (twosComplement, _) = maximum.subtractingReportingOverflow(base.magnitude)
            data = twosComplement.serialize()
        }

        let bytes = data.web3.bytes
        let lastIndex = bytes.count - 1
        let firstIndex = bytes.firstIndex(where: {$0 != 0x00}) ?? lastIndex

        if lastIndex < 0 {
            return Array([0])
        }

        return Array(bytes[firstIndex...lastIndex])
    }
}

public extension Data {
    static func ^ (lhs: Data, rhs: Data) -> Data {
        let bytes = zip(lhs.web3.bytes, rhs.web3.bytes).map { lhsByte, rhsByte in
            return lhsByte ^ rhsByte
        }

        return Data(bytes)
    }
}

public extension Web3Extensions where Base == Data {
    var bytes: [UInt8] {
        return Array(base)
    }

    var strippingZeroesFromBytes: Data {
        var bytes = self.bytes
        while bytes.first == 0 {
            bytes.removeFirst()
        }
        return Data.init(bytes)
    }

    var bytes4: Data {
        return base.prefix(4)
    }

    var bytes32: Data {
        return base.prefix(32)
    }
}

public extension String {
    init(hexFromBytes bytes: [UInt8]) {
        self.init("0x" + bytes.map { String(format: "%02x", $0) }.reduce("", +))
    }
}

public extension Web3Extensions where Base == String {
    var bytes: [UInt8] {
        return [UInt8](base.utf8)
    }

    var bytesFromHex: [UInt8]? {
        let hex = noHexPrefix
        do {
            let byteArray = try HexUtil.byteArray(fromHex: hex)
            return byteArray
        } catch {
            return nil
        }
    }
}
