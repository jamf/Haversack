// SPDX-License-Identifier: MIT
// Copyright 2024, Jamf

import CryptoKit
import Foundation
import Haversack
import os.log

// MARK: - SecKeyConvertible

/// Protocol for CryptoKit key types that can be converted to `SecKey` representations.
public protocol SecKeyConvertible {
    /// Creates a key from an X9.63 representation.
    init<Bytes>(x963Representation: Bytes) throws where Bytes: ContiguousBytes

    /// An X9.63 representation of the key.
    var x963Representation: Data { get }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, visionOS 1.0, *)
extension P256.Signing.PrivateKey: SecKeyConvertible {}
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, visionOS 1.0, *)
extension P256.KeyAgreement.PrivateKey: SecKeyConvertible {}
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, visionOS 1.0, *)
extension P384.Signing.PrivateKey: SecKeyConvertible {}
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, visionOS 1.0, *)
extension P384.KeyAgreement.PrivateKey: SecKeyConvertible {}
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, visionOS 1.0, *)
extension P521.Signing.PrivateKey: SecKeyConvertible {}
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, visionOS 1.0, *)
extension P521.KeyAgreement.PrivateKey: SecKeyConvertible {}

// MARK: - storage

public extension KeyEntity {
    /// Attempt to construct a ``KeyEntity`` from a CryptoKit type that is convertible to a `SecKey`.
    ///
    /// This converts the type in RAM only.  The `reference` and `keyClass` attributes will be set on
    /// the returned ``KeyEntity``.
    /// > Tip: In order to persist the key to the keychain, one of the Haversack `save()` methods should be used
    /// with the initialized ``KeyEntity``.
    /// - Parameter key: A CryptoKit elliptic key
    /// - Throws: Throws an `NSError` if there is a problem converting to a `SecKey`
    convenience init<T: SecKeyConvertible>(_ key: T) throws {
        let attributes = [kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
                          kSecAttrKeyClass: kSecAttrKeyClassPrivate] as [String: Any]
        var possibleError: Unmanaged<CFError>?

        // Get a SecKey representation
        guard let secKey = SecKeyCreateWithData(key.x963Representation as CFData,
                                                attributes as CFDictionary,
                                                &possibleError) else {
            if let error = possibleError {
                throw error.takeRetainedValue()
            }
            throw HaversackError.notPossible("Unable to create SecKey representation.")
        }

        self.init(from: secKey, data: nil, attributes: attributes, persistentRef: nil)
    }

    /// Converts the loaded `reference` into another type that conforms to ``SecKeyConvertible``.
    ///
    /// - Important: Make sure that the type of the thing that you try to create here matches the type of the thing originally
    /// stored in the keychain.
    /// - Returns: An instance of a type that the ``KeyEntity`` was originally created with.
    /// - Throws: An `HaversackError.notPossible` if the `reference` field of this entity is nil.  May throw
    /// an `NSError` if the `SecKey` cannot be used to create the requested type.  This would usually be due
    /// to a type mismatch such as storing a `P521` and trying to create a `P384` from it.
    func originalEntity<T: SecKeyConvertible>() throws -> T {
        guard let theReference = reference else {
            os_log("Cannot convert to original entity of type %{public}@ because data has not been loaded",
                   log: OSLog(subsystem: "com.jamf.haversack", category: "cryptokit"),
                   type: .error, String(describing: T.self))
            throw HaversackError.notPossible("Cannot convert to original entity of type \(T.self) because reference has not been loaded")
        }

        // Convert the SecKey into a CryptoKit key.
        var possibleError: Unmanaged<CFError>?
        guard let data = SecKeyCopyExternalRepresentation(theReference, &possibleError) as Data? else {
            if let error = possibleError {
                throw error.takeRetainedValue()
            }
            os_log("Unable to copy external representation of SecKey",
                   log: OSLog(subsystem: "com.jamf.haversack", category: "cryptokit"),
                   type: .error)
            throw HaversackError.notPossible("Unable to copy external representation of SecKey.")
        }

        return try T(x963Representation: data)
    }
}
