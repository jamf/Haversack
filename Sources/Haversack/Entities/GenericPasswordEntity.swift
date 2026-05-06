// SPDX-License-Identifier: MIT
// Copyright 2026, Jamf

import Foundation
@preconcurrency import Security

/// Represents a password to anything in the keychain.
///
/// The combination of `service` and `account` values is unique per generic password in the keychain.
public struct GenericPasswordEntity: PasswordBaseEntity {
#if os(macOS)
    /// The native Security framework type associated with `PasswordBaseEntity`
    ///
    /// On macOS uses the `SecKeychainItem` type to interface with the Security framework.
    /// On iOS uses the [Data](https://developer.apple.com/documentation/Foundation/Data)
    /// type to interface with the Security framework.
    public typealias SecurityFrameworkType = SecKeychainItem
#else
    /// The native Security framework type associated with `PasswordBaseEntity`
    ///
    /// On macOS uses the `SecKeychainItem` type to interface with the Security framework.
    /// On iOS uses the [Data](https://developer.apple.com/documentation/Foundation/Data)
    /// type to interface with the Security framework.
    public typealias SecurityFrameworkType = Data
#endif

    /// The keychain item reference, if it has been returned.
    public var reference: SecurityFrameworkType?

    /// The persistent keychain item reference, if it has been returned.
    public var persistentRef: Data?

    /// When the item was created; read only.
    /// - Note: Uses `kSecAttrCreationDate`
    public private(set) var creationDate: Date?

    /// When the item was last modified; read only.
    /// - Note: Uses `kSecAttrModificationDate`
    public private(set) var modificationDate: Date?

    /// The item's creator.
    /// - Note: Uses `kSecAttrCreator`
    public var creator: Int?    // FourCharCode

    /// A description to store alongside the item.
    ///
    /// In Keychain Access this is the `Kind` field.
    /// - Note: Uses `kSecAttrDescription`
    public var description: String?

    /// A comment to store alongside the item.
    ///
    /// In Keychain Access this is the `Comment` field.
    /// - Note: Uses `kSecAttrComment`.
    public var comment: String?

    /// User-defined group number for passwords
    /// - Note: Uses `kSecAttrType`
    public var group: Int?     // FourCharCode

    /// A user-visible label for the item.
    ///
    /// In Keychain Access this is the `Name` field.
    /// - Note: Uses `kSecAttrLabel`
    public var label: String?

    /// Whether you want this to show up in Keychain Access.
    /// - Note: Uses `kSecAttrIsInvisible`
    public var isInvisible: Bool?

    /// The name of an account within a service associated with the password.
    ///
    /// In Keychain Access this is the `Account` field.
    /// - Note: Uses `kSecAttrAccount`
    public var account: String?

    /// The actual password.
    ///
    /// If this is nil, when saving to the keychain the `kSecAttrIsNegative` is set to `true` instead.
    /// - Note: Uses `kSecValueData`.
    public var passwordData: Data?

    /// The name of the service associated with the password.
    ///
    /// In Keychain Access this is the `Where` field.
    /// - Note: Uses `kSecAttrService`
    public var service: String?

    /// User-defined [Data](https://developer.apple.com/documentation/Foundation/Data) that can be used for anything.
    /// - Note: Uses `kSecAttrGeneric`
    public var customData: Data?

    /// Create an empty generic password entity
    public init() {
        // Everything is nil with this constructor.
    }

    /// Returns a ``GenericPasswordEntity`` object initialized to correspond to an existing keychain item.
    /// - Parameters:
    ///   - keychainItemRef: If given, a reference to an existing keychain item.
    ///   - data: If given, the raw unencrypted data of the password.
    ///   - attributes: If given, the attributes of an existing keychain item.
    ///   - persistentRef: If given, a persistent reference to an existing keychain item.
    public init(from keychainItemRef: SecurityFrameworkType?, data: Data?,
                attributes: [String: Any]?, persistentRef: Data?) {
        reference = keychainItemRef
        passwordData = data
        self.persistentRef = persistentRef

        if let attrs = attributes {
            creationDate = attrs[kSecAttrCreationDate as String] as? Date
            modificationDate = attrs[kSecAttrModificationDate as String] as? Date
            label = attrs[kSecAttrLabel as String] as? String
            account = attrs[kSecAttrAccount as String] as? String
            group = attrs[kSecAttrType as String] as? Int
            comment = attrs[kSecAttrComment as String] as? String
            description = attrs[kSecAttrDescription as String] as? String
            creator = attrs[kSecAttrCreator as String] as? Int
            service = attrs[kSecAttrService as String] as? String
            customData = attrs[kSecAttrGeneric as String] as? Data
        }
    }

    // MARK: - KeychainStorable

    public func entityQuery(includeSecureData: Bool) -> SecurityFrameworkQuery {
        var query = _entityQuery(includeSecureData: includeSecureData)

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
