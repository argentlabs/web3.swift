//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import BigInt
import Foundation

struct RLP {
    static func encode(_ item: Any) -> Data? {
        switch item {
        case let int as Int:
            return encodeInt(int)
        case let string as String:
            return encodeString(string)
        case let bint as BigInt:
            return encodeBigInt(bint)
        case let array as [Any]:
            return encodeArray(array)
        case let buint as BigUInt:
            return encodeBigUInt(buint)
        case let data as Data:
            return encodeData(data)
        default:
            return nil
        }
    }

    static func encodeString(_ string: String) -> Data? {
        if let hexData = string.web3.hexData {
            return encodeData(hexData)
        }

        guard let data = string.data(using: String.Encoding.utf8) else {
            return nil
        }
        return encodeData(data)
    }

    static func encodeInt(_ int: Int) -> Data? {
        guard int >= 0 else {
            return nil
        }
        return encodeBigInt(BigInt(int))
    }

    static func encodeBigInt(_ bint: BigInt) -> Data? {
        guard bint >= 0 else {
            // TODO: implement properly to support negatives if RLP supports.. twos complement reverse?
            return nil
        }
        return encodeBigUInt(BigUInt(bint))
    }

    static func encodeBigUInt(_ buint: BigUInt) -> Data? {
        let data = buint.serialize()

        let lastIndex = data.count - 1
        let firstIndex = data.firstIndex(where: { $0 != 0x00 }) ?? lastIndex
        if lastIndex == -1 {
            return Data([0x80])
        }
        let subdata = data.subdata(in: firstIndex ..< lastIndex + 1)

        if subdata.count == 1, subdata[0] == 0x00 {
            return Data([0x80])
        }

        return encodeData(data.subdata(in: firstIndex ..< lastIndex + 1))
    }

    static func encodeData(_ data: Data) -> Data {
        if data.count == 1, data[0] <= 0x7f {
            return data // single byte, no header
        }

        var encoded = encodeHeader(size: UInt64(data.count), smallTag: 0x80, largeTag: 0xb7)
        encoded.append(data)
        return encoded
    }

    static func encodeArray(_ elements: [Any]) -> Data? {
        var encodedData = Data()
        for el in elements {
            guard let encoded = encode(el) else {
                return nil
            }
            encodedData.append(encoded)
            /* if let encoded = encode(el) {
                 encodedData.append(encoded)
             } else if let emptyPlaceholder = encodeString("") {
                 encodedData.append(emptyPlaceholder)
             } */
        }

        var encoded = encodeHeader(size: UInt64(encodedData.count), smallTag: 0xc0, largeTag: 0xf7)
        encoded.append(encodedData)
        return encoded
    }

    static func encodeHeader(size: UInt64, smallTag: UInt8, largeTag: UInt8) -> Data {
        if size < 56 {
            return Data([smallTag + UInt8(size)])
        }

        let sizeData = bigEndianBinary(size)
        var encoded = Data()
        encoded.append(largeTag + UInt8(sizeData.count))
        encoded.append(contentsOf: sizeData)
        return encoded
    }

    // in Ethereum integers must be represented in big endian binary form with no leading zeroes
    static func bigEndianBinary(_ i: UInt64) -> Data {
        var value = i
        var bytes = withUnsafeBytes(of: &value) { Array($0) }
        for (index, byte) in bytes.enumerated().reversed() {
            if index != 0, byte == 0x00 {
                bytes.remove(at: index)
            } else {
                break
            }
        }
        return Data(bytes.reversed())
    }
}
