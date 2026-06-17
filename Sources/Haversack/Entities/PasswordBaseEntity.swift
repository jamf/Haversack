// SPDX-License-Identifier: MIT
// Copyright 2026, Jamf

import Foundation

/// Protocol for the ``GenericPasswordEntity`` and the ``InternetPasswordEntity``
/// that handles storage and minor processing of shared data fields.
public protocol PasswordBaseEntity: KeychainStorable {
    /// The keychain item reference, if it has been returned.
    var reference: SecurityFrameworkType? { get set }

    /// The persistent keychain item reference, if it has been returned.
    var persistentRef: Data? { get set }

    /// When the item was created; read only.
    /// - Note: Uses `kSecAttrCreationDate`
    var creationDate: Date? { get }

    /// When the item was last modified; read only.
    /// - Note: Uses `kSecAttrModificationDate`
    var modificationDate: Date? { get }

    /// The item's creator.
    /// - Note: Uses `kSecAttrCreator`
    var creator: Int? { get set }    // FourCharCode

    /// A description to store alongside the item.
    ///
    /// In Keychain Access this is the `Kind` field.
    /// - Note: Uses `kSecAttrDescription`
    var description: String? { get set }

    /// A comment to store alongside the item.
    ///
    /// In Keychain Access this is the `Comment` field.
    /// - Note: Uses `kSecAttrComment`.
    var comment: String? { get set }

    /// User-defined group number for passwords
    /// - Note: Uses `kSecAttrType`
    var group: Int? { get set }    // FourCharCode

    /// A user-visible label for the item.
    ///
    /// In Keychain Access this is the `Name` field.
    /// - Note: Uses `kSecAttrLabel`
    var label: String? { get set }

    /// Whether you want this to show up in Keychain Access.
    /// - Note: Uses `kSecAttrIsInvisible`
    var isInvisible: Bool? { get set }

    /// Useful if you want to never store the actual password, but still have a keychain item.
    var isNegative: Bool { get }

    /// The name of an account within a service associated with the password.
    ///
    /// In Keychain Access this is the `Account` field.
    /// - Note: Uses `kSecAttrAccount`
    var account: String? { get set }

    /// The actual password.
    ///
    /// If this is nil, when saving to the keychain the `kSecAttrIsNegative` is set to `true` instead.
    /// - Note: Uses `kSecValueData`.
    var passwordData: Data? { get set }

    func entityQuery(includeSecureData: Bool) -> SecurityFrameworkQuery
}

extension PasswordBaseEntity {
    /// Useful if you want to never store the actual password, but still have a keychain item.
    public var isNegative: Bool {
        return passwordData == nil
    }

    // NOTE: This function has a cyclomatic complexity of 11 instead of the allowed 10.
    // swiftlint:disable:next identifier_name cyclomatic_complexity
    func _entityQuery(includeSecureData: Bool) -> SecurityFrameworkQuery {
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
