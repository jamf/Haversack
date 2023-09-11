// SPDX-License-Identifier: MIT
// Copyright 2023, Jamf

import Foundation

/// Superclass of the ``GenericPasswordEntity`` and the ``InternetPasswordEntity`` that
/// handles storage and minor processing of shared data fields.  The `PasswordBaseEntity` is never
/// instantiated on its own.
public class PasswordBaseEntity: KeychainStorable {
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
    private(set) var creationDate: Date?

    /// When the item was last modified; read only.
    /// - Note: Uses `kSecAttrModificationDate`
    private(set) var modificationDate: Date?

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

    /// Useful if you want to never store the actual password, but still have a keychain item.
    public var isNegative: Bool {
        return passwordData == nil
    }

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

    /// Everything is nil with this constructor.
    public init() { }

    public required init(from keychainItemRef: SecurityFrameworkType?, data: Data?,
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
        }
    }

    // NOTE: This function has a cyclomatic complexity of 11 instead of the allowed 10.
    // swiftlint:disable:next cyclomatic_complexity
    public func entityQuery(includeSecureData: Bool) -> SecurityFrameworkQuery {
        var newQuery = SecurityFrameworkQuery()

        if let theReference = reference {
            newQuery[kSecValueRef as String] = theReference
        }

        if let thePersistentRef = persistentRef {
            newQuery[kSecValuePersistentRef as String] = thePersistentRef
        }

        if let theLabel = label {
            newQuery[kSecAttrLabel as String] = theLabel
        }

        if let theAccount = account {
            newQuery[kSecAttrAccount as String] = theAccount
        }

        if let theGroup = group {
            newQuery[kSecAttrType as String] = theGroup
        }

        if let theIsInvisible = isInvisible {
            newQuery[kSecAttrIsInvisible as String] = theIsInvisible
        }

        if let theComment = comment {
            newQuery[kSecAttrComment as String] = theComment
        }

        if let theDescription = description {
            newQuery[kSecAttrDescription as String] = theDescription
        }

        if let theCreator = creator {
            newQuery[kSecAttrCreator as String] = theCreator
        }

        if includeSecureData {
            if let thePassword = passwordData {
                newQuery[kSecValueData as String] = thePassword
            } else {
                newQuery[kSecAttrIsNegative as String] = true
            }
        }

        return newQuery
    }
}
