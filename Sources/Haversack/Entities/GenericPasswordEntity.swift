// SPDX-License-Identifier: MIT
// Copyright 2023, Jamf

import Foundation

/// Represents a password to anything in the keychain.
///
/// The combination of `service` and `account` values is unique per generic password in the keychain.
public class GenericPasswordEntity: PasswordBaseEntity {
    /// The name of the service associated with the password.
    ///
    /// In Keychain Access this is the `Where` field.
    /// - Note: Uses `kSecAttrService`
    public var service: String?

    /// User-defined [Data](https://developer.apple.com/documentation/Foundation/Data) that can be used for anything.
    /// - Note: Uses `kSecAttrGeneric`
    public var customData: Data?

    /// Create an empty generic password entity
    override public init() {
        super.init()
    }

    /// Returns a ``GenericPasswordEntity`` object initialized to correspond to an existing keychain item.
    /// - Parameters:
    ///   - keychainItemRef: If given, a reference to an existing keychain item.
    ///   - data: If given, the raw unencrypted data of the password.
    ///   - attributes: If given, the attributes of an existing keychain item.
    ///   - persistentRef: If given, a persistent reference to an existing keychain item.
    public required init(from keychainItemRef: SecurityFrameworkType?, data: Data?,
                         attributes: [String: Any]?, persistentRef: Data?) {
        super.init(from: keychainItemRef, data: data, attributes: attributes, persistentRef: persistentRef)

        if let attrs = attributes {
            service = attrs[kSecAttrService as String] as? String
            customData = attrs[kSecAttrGeneric as String] as? Data
        }
    }

    // MARK: - KeychainStorable

    override public func entityQuery(includeSecureData: Bool) -> SecurityFrameworkQuery {
        var query = super.entityQuery(includeSecureData: includeSecureData)

        query[kSecClass as String] = kSecClassGenericPassword

        if let theService = service {
            query[kSecAttrService as String] = theService
        }

        if let theCustomData = customData {
            query[kSecAttrGeneric as String] = theCustomData
        }

        return query
    }
}
