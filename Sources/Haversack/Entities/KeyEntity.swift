// SPDX-License-Identifier: MIT
// Copyright 2023, Jamf

import Foundation

/// Represents a public or private key in the keychain.
public class KeyEntity: KeychainStorable, KeychainPortable {
    /// Uses the `SecKey` type to interface with the Security framework.
    public typealias SecurityFrameworkType = SecKey

    /// The keychain item reference, if it has been returned.
    public var reference: SecurityFrameworkType?

    /// The persistent keychain item reference, if it has been returned.
    public var persistentRef: Data?

    /// The raw key data.
    public var keyData: Data?

    /// A user-visible label for the item.
    /// - Note: Uses `kSecAttrLabel`
    public var label: String?

    /// Specifies what the key class (public/private/symmetric); read only.
    /// - Note: Uses `kSecAttrKeyClass`
    public var keyClass: KeyClass?

    /// Specifies the number of bits in this key; read only.
    /// - Note: Uses `kSecAttrKeySizeInBits`
    public var keySizeInBits: Int?

    /// Specifies the effective number of bits in this key; read only.
    /// - Note: Uses `kSecAttrEffectiveKeySize`
    public var effectiveKeySizeInBits: Int?

    /// Specifies the type of things the key should be used for.
    /// - Tip: See ``KeyUsagePolicy`` type for all of the Security Framework keys used.
    public var keyUsage: KeyUsagePolicy?

    /// Specifies the application specific tag for this key.
    ///
    /// In Keychain Access this is the `Comment` field.
    /// - Note: Uses `kSecAttrApplicationTag`
    public var tag: Data?

    /// Specifies the application specific label (not human readable) for this key.
    ///
    /// Some old keys may have a CFString in the application label attribute.  If the key had such a label, the string
    /// will be converted into a [Data](https://developer.apple.com/documentation/Foundation/Data) with the UTF-8 encoding.
    /// - Note: Uses [kSecAttrApplicationLabel](https://developer.apple.com/documentation/security/ksecattrapplicationlabel/)
    public var appLabel: Data?

    /// Create an empty key entity
    public init() { }

    public required init(from keychainItemRef: SecurityFrameworkType?, data: Data?,
                         attributes: [String: Any]?, persistentRef: Data?) {
        reference = keychainItemRef
        keyData = data
        self.persistentRef = persistentRef

        if let attrs = attributes {
            label = attrs[kSecAttrLabel as String] as? String
            if let possibleKeyClass = attrs[kSecAttrKeyClass as String] as? String {
                keyClass = .make(from: possibleKeyClass as CFString)
            }
            keySizeInBits = attrs[kSecAttrKeySizeInBits as String] as? Int
            effectiveKeySizeInBits = attrs[kSecAttrEffectiveKeySize as String] as? Int
            keyUsage = .make(from: attrs)
            tag = attrs[kSecAttrApplicationTag as String] as? Data
            if let legacyAppLabel = attrs[kSecAttrApplicationLabel as String] as? String {
                // Some old keys may have a CFString in the application label attribute.
                appLabel = legacyAppLabel.data(using: .utf8)
            } else {
                appLabel = attrs[kSecAttrApplicationLabel as String] as? Data
            }
        }
    }

    // MARK: - KeychainStorable

    public func entityQuery(includeSecureData: Bool) -> SecurityFrameworkQuery {
        var newQuery = SecurityFrameworkQuery()

        newQuery[kSecClass as String] = kSecClassKey

        if let theReference = reference {
            newQuery[kSecValueRef as String] = theReference
        }

        if let thePersistentRef = persistentRef {
            newQuery[kSecValuePersistentRef as String] = thePersistentRef
        }

        if let theLabel = label {
            newQuery[kSecAttrLabel as String] = theLabel
        }

        if let theKeyClass = keyClass {
            newQuery[kSecAttrKeyClass as String] = theKeyClass.securityFrameworkValue()
        }

        if let theKeyUsage = keyUsage {
            theKeyUsage.securityFrameworkKeyArray.forEach { (key) in
                newQuery[key as String] = true
            }
        }

        if let theTag = tag {
            newQuery[kSecAttrApplicationTag as String] = theTag
        }

        if let theAppLabel = appLabel {
            newQuery[kSecAttrApplicationLabel as String] = theAppLabel
        }

        if includeSecureData, let secureData = keyData {
            newQuery[kSecValueData as String] = secureData
        }

        return newQuery
    }
}
