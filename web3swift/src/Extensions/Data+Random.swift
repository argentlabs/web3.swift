//
//  Data+Random.swift
//  web3s
//
//  Created by Matt Marshall on 13/03/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation

extension Data {
    static func randomOfLength(_ length: Int) -> Data? {
        return Data((0 ..< length).map { _ in UInt8.random(in: UInt8.min ... UInt8.max) })
    }
}
