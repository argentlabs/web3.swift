//
//  ConversionExtension.swift
//  web3swift
//
//  Created by Philippe Mercier on 09/03/2020.
//  Copyright © 2020 Argent Labs Limited. All rights reserved.
//

import Foundation
import BigInt

public extension Web3Extensions where Base == BigUInt {
    // from ether to wei
    var toWei: BigUInt {
        return base * BigUInt(10).power(18)
    }
    
    // from ether to gwei
    var toGwei: BigUInt {
        return base * BigUInt(10).power(9)
    }
}
