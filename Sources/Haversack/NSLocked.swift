// SPDX-License-Identifier: MIT
// Copyright 2026, Jamf

import Foundation

@propertyWrapper
public struct NSLocked<T>: @unchecked Sendable {
    private let lock = NSLock()
    private var value: T

    public init(wrappedValue: T) {
        value = wrappedValue
    }

    public var wrappedValue: T {
        get {
            lock.withLock {
                value
            }
        }
        set {
            lock.withLock {
                value = newValue
            }
        }
    }
}
