//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation

public struct OffchainLookup: ABIRevertError {
    public var expectedTypes: [ABIType.Type] {
        [
            EthereumAddress.self,
            ABIArray<String>.self,
            Data.self,
            Data4.self,
            Data.self
        ]
    }

    public static var name: String = "OffchainLookup"

    public var address: EthereumAddress
    public var urls: [String]
    public var callData: Data
    public var callbackFunction: Data
    public var extraData: Data

    public func encode(to encoder: ABIFunctionEncoder) throws {
        try encoder.encode(address)
        try encoder.encode(urls)
        try encoder.encode(callData)
        try encoder.encode(callbackFunction, staticSize: 4)
        try encoder.encode(extraData)
    }

    public init(
        address: EthereumAddress,
        urls: [String],
        callData: Data,
        callbackFunction: Data,
        extraData: Data
    ) {
        self.address = address
        self.urls = urls
        self.callData = callData
        self.callbackFunction = callbackFunction
        self.extraData = extraData
    }

    init?(
        decoded: [ABIDecoder.DecodedValue]
    ) {
        guard let sender = decoded.sender,
              let urls = decoded.urls,
              let callData = decoded.callData,
              let callbackFunction = decoded.callbackFunction,
              let extraData = decoded.extraData
        else {
            return nil
        }

        self.init(
            address: sender,
            urls: urls,
            callData: callData,
            callbackFunction: callbackFunction,
            extraData: extraData
        )
    }
}

extension JSONRPCErrorResult {
    var offchainLookup: OffchainLookup? {
        return (try? error.decode(error: expected)).flatMap(OffchainLookup.init(decoded:))
    }
}

extension OffchainLookup {
    func encodeCall(withResponse data: Data) -> Data {
        let encodedCall = try? [data, extraData].map {
            try ABIEncoder.encode($0)
        }.encoded(isDynamic: false)
        return callbackFunction + Data(encodedCall ?? [])
    }
}

private let expected = OffchainLookup(
    address: .zero,
    urls: [],
    callData: Data(),
    callbackFunction: Data(),
    extraData: Data()
)

fileprivate extension Array where Element == ABIDecoder.DecodedValue {
    var sender: EthereumAddress? {
        try? self[0].decoded()
    }
    var urls: [String]? {
        try? self[1].decodedArray()
    }
    var callData: Data? {
        try? self[2].decoded()
    }
    var callbackFunction: Data? {
        try? self[3].decoded()
    }
    var extraData: Data? {
        try? self[4].decoded()
    }
}
