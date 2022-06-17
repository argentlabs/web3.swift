//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation
import NIOCore

public enum EventLoopGroupProvider {
    case shared(EventLoopGroup)
    case createNew
}
