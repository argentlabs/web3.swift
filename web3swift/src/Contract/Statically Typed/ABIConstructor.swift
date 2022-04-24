//  Created by Rinat Enikeev on 23.04.2022.

import Foundation
import BigInt

public protocol ABIConstructor {
    static var bytecode: Data { get }
    var gasPrice: BigUInt? { get }
    var gasLimit: BigUInt? { get }
    var from: EthereumAddress? { get }
    func encode(to encoder: ABIConstructorEncoder) throws
}

extension ABIConstructor {
    public func transaction(
        gasPrice: BigUInt? = nil,
        gasLimit: BigUInt? = nil
    ) throws -> EthereumTransaction {
        let encoder = ABIConstructorEncoder(Self.bytecode)
        try self.encode(to: encoder)
        let data = try encoder.encoded()

        return EthereumTransaction(
            from: from,
            to: EthereumAddress("0x"),
            data: data,
            gasPrice: self.gasPrice ?? gasPrice ?? 0,
            gasLimit: self.gasLimit ?? gasLimit ?? 0
        )
    }
}
