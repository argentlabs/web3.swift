//
//  web3.swift
//  Copyright © Argent Labs Limited. All rights reserved.
//

import Foundation

/// Thread-safe wrapper class that can be used as a let property
final class ThreadSafeBox<Value>: @unchecked Sendable {
    private var _value: Value
    private let lock = NSLock()

    init(_ value: Value) {
        self._value = value
    }

    var value: Value {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _value
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _value = newValue
        }
    }

    /// Allows for atomic read-modify-write operations
    func withLock<T>(_ operation: (inout Value) throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try operation(&_value)
    }
}
