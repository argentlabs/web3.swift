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
        var data = [UInt8](repeating: 0, count: length)
        let result = SecRandomCopyBytes(kSecRandomDefault,
                               data.count,
                               &data)
        if result == errSecSuccess {
            return Data(data)
        }
        
        return nil
    }
}
