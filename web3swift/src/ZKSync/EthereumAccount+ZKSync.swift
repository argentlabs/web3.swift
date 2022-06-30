//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation

extension EthereumAccountProtocol {
    func sign(zkTransaction: ZKSyncTransaction) throws -> ZKSyncSignedTransaction {
        let typed = zkTransaction.eip712Representation
        let signature = try signMessage(message: typed).web3.hexData!
        let sigParam: ZKSyncSignedTransaction.SignatureParam
        if let aaParams = zkTransaction.aaParams {
            sigParam = .aa(signature: .init(raw: signature), from: aaParams.from)
        } else {
            sigParam = .eoa(.init(raw: signature))
        }
        return .init(
            transaction: zkTransaction,
            sigParam: sigParam
        )
    }
}
