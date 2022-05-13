//
//  ABIRevertError.swift
//  web3swift
//
//  Created by Miguel on 12/05/2022.
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation

// Technically an ABI error is the same as a function in the way it's encoded
// But use different type to be more explicit, as some extensions
// on ABIFunction don't matter for ABIError (i.e. to generate a transaction)
public protocol ABIRevertError: ABIFunctionEncodable {
    var expectedTypes: [ABIType.Type] { get }
}

extension JSONRPCErrorDetail {
    public func decode<T: ABIRevertError>(error: T) throws -> [ABIDecoder.DecodedValue] {
        guard let data = data?.web3.hexData else {
            throw ABIError.invalidType
        }

        return try error.decode(
            data,
            expectedTypes: error.expectedTypes,
            filteringEmptyEntries: false
        )
    }
}
