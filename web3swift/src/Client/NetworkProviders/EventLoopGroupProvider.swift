//
//  web3.swift
//  Copyright © Argent Labs Limited. All rights reserved.
//

#if canImport(NIO)

    import NIOCore
    import Foundation

    public enum EventLoopGroupProvider {
        case shared(EventLoopGroup)
        case createNew
    }

#endif
