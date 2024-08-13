//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import web3
import Foundation

extension EthereumAccountProtocol {
    func sign(zkTransaction: ZKSyncTransaction) throws -> ZKSyncSignedTransaction {
        let typed = zkTransaction.eip712Representation
        let signature = try signMessage(message: typed).web3.hexData!

        return .init(
            transaction: zkTransaction,
            signature: .init(raw: signature)
        )
    }
}
