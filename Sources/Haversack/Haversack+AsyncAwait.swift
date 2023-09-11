// SPDX-License-Identifier: MIT
// Copyright 2023, Jamf

import Foundation

@available(macOS 10.15.0, iOS 13.0.0, tvOS 13.0.0, watchOS 6.0, *)
extension Haversack {
    /// This is equivalent to calling ``first(where:completionQueue:completion:)`` but using async-await syntax.
    public func first<T: KeychainQuerying>(where query: T) async throws -> T.Entity {
        try await withCheckedThrowingContinuation { continuation in
            first(where: query, completion: continuation.resume)
        }
    }

    /// This is equivalent to calling ``search(where:completionQueue:completion:)`` but using async-await syntax.
    public func search<T: KeychainQuerying>(where query: T) async throws -> [T.Entity] {
        try await withCheckedThrowingContinuation { continuation in
            search(where: query, completion: continuation.resume)
        }
    }

    /// This is equivalent to calling ``save(_:itemSecurity:updateExisting:completionQueue:completion:)`` but using async-await syntax.
    @discardableResult
    public func save<T: KeychainStorable>(_ item: T, itemSecurity: ItemSecurity, updateExisting: Bool) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            save(item, itemSecurity: itemSecurity, updateExisting: updateExisting, completion: continuation.resume)
        }
    }

    /// This is equivalent to calling ``generateKey(fromConfig:itemSecurity:completionQueue:completion:)`` but using async-await syntax.
    public func generateKey(fromConfig config: KeyGenerationConfig, itemSecurity: ItemSecurity) async throws -> SecKey {
        try await withCheckedThrowingContinuation { continuation in
            generateKey(fromConfig: config, itemSecurity: itemSecurity, completion: continuation.resume)
        }
    }

    /// This is equivalent to calling ``delete(where:treatNotFoundAsSuccess:completionQueue:completion:)`` but using async-await syntax.
    public func delete<T: KeychainQuerying>(where query: T, treatNotFoundAsSuccess: Bool = true) async throws {
        let error = try await withCheckedThrowingContinuation { continuation in
            delete(where: query, treatNotFoundAsSuccess: treatNotFoundAsSuccess, completion: continuation.resume)
        }

        if let error = error {
            throw error
        }
    }

    /// This is equivalent to calling ``delete(_:treatNotFoundAsSuccess:completionQueue:completion:)`` but using async-await syntax.
    public func delete<T: KeychainStorable>(_ item: T, treatNotFoundAsSuccess: Bool = true) async throws {
        let error = try await withCheckedThrowingContinuation { continuation in
            delete(item, treatNotFoundAsSuccess: treatNotFoundAsSuccess, completion: continuation.resume)
        }

        if let error = error {
            throw error
        }
    }
}
