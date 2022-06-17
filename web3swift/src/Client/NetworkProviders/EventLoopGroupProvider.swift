//
//  EventLoopGroupProvider.swift
//  web3swift
//
//  Created by Dionisios Karatzas on 16/6/22.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation
import NIOCore

public enum EventLoopGroupProvider {
    case shared(EventLoopGroup)
    case createNew
}
