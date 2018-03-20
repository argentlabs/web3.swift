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
        var data = Data(count: length)
        
        let result = data.withUnsafeMutableBytes { mutableBytes in
            SecRandomCopyBytes(kSecRandomDefault, data.count, mutableBytes)
        }
        
        if result == errSecSuccess {
            return data
        }
        
        return nil
    }
}
