// SPDX-License-Identifier: MIT
// Copyright 2023, Jamf

import Foundation

/// Represents any item that is storable in the keychain.
public protocol KeychainStorable {
    /// This should be one of the SecFoo types, such as `SecCertificate` or `SecKeychainItem`
    associatedtype SecurityFrameworkType

    /// The keychain item reference, if it has been returned.
    var reference: SecurityFrameworkType? { get }

    /// The persistent keychain item reference, if it has been returned.
    var persistentRef: Data? { get }

    /// Initialize a `KeychainStorable` type from keychain data.
    /// - Parameters:
    ///   - keychainItemRef: A keychain item reference such as a `SecCertificate` or `SecIdentity`
    ///   - data: The raw data of the keychain item; for passwords this is the unencrypted password data.
    ///   - attributes: The keychain attributes associated with the item
    ///   - persistentRef: A persistent reference to the keychain item
    init(from keychainItemRef: SecurityFrameworkType?, data: Data?, attributes: [String: Any]?, persistentRef: Data?)

    /// The item must be able to generate a query to use with `SecItemAdd` or `SecItemDelete`.
    /// - Parameter includeSecureData: Whether to include the secure data (if it has been loaded) in the query.
    ///
    /// The item's keychain class must be included with the `kSecClass` key.
    /// For `SecItemDelete` the secure data is not needed in the query.
    func entityQuery(includeSecureData: Bool) -> SecurityFrameworkQuery
}
