//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

#if canImport(NIO)

    import NIOCore
    import Foundation

    public enum EventLoopGroupProvider {
        case shared(EventLoopGroup)
        case createNew
    }

#endif
