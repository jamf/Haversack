// SPDX-License-Identifier: MIT
// Copyright 2023, Jamf

import Foundation

/// A common dictionary type for all Security framework queries used by Haversack.
public typealias SecurityFrameworkQuery = [String: Any]

/// Base protocol for the fluent interface to search for a keychain item
public protocol KeychainQuerying {
    /// The type of entity that is created when searching the keychain with this query.
    associatedtype Entity: KeychainStorable

    /// The keychain query.
    ///
    /// You should not manipulate this directly.  Instead use the fluent methods such as `returning`,
    /// `stringMatching(options:)`, and others from the concrete type that conforms to ``KeychainQuerying``
    /// in order to build up the query.
    var query: SecurityFrameworkQuery { get set }

    /// What data to include from the keychain.  If this is not called at all, the `.data` will be returned.
    /// - Parameter include: What type of data to be returned.
    func returning(_ include: KeychainDataOptions) -> Self

    /// Specify a keychain access group that the item must be part of.  Uses `kSecAttrAccessGroup`.
    ///
    /// See [Apple: Sharing Keychain Items](https://developer.apple.com/documentation/security/keychain_services/keychain_items/sharing_access_to_keychain_items_among_a_collection_of_apps)
    /// for more information.
    /// - Parameter keychainGroup: The keychain group the item must be part of.
    /// - Returns: A new instance of it's own type
    func containedIn(keychainGroup: String) -> Self

    /// Specify how to do string comparisons for this query.
    /// - Parameter options: One or more of the ``KeychainStringComparisonOptions`` constants.
    func stringMatching(options: KeychainStringComparisonOptions) -> Self
}

public extension KeychainQuerying {
    /// Set the type of data to be returned from the query.
    /// - Parameter include: One or more of the ``KeychainDataOptions`` values.
    /// - Returns: A new instance of it's own type
    func returning(_ include: KeychainDataOptions) -> Self {
        var copy = self
        if include.contains(.attributes) {
            copy.query[kSecReturnAttributes as String] = true
        }
        if include.contains(.data) {
            copy.query[kSecReturnData as String] = true
        }
        if include.contains(.persistantReference) {
            copy.query[kSecReturnPersistentRef as String] = true
        }
        if include.contains(.reference) {
            copy.query[kSecReturnRef as String] = true
        }
        return copy
    }

    /// Specify a keychain access group that the item must be part of.  Uses `kSecAttrAccessGroup`.
    ///
    /// See [Apple: Sharing Keychain Items](https://developer.apple.com/documentation/security/keychain_services/keychain_items/sharing_access_to_keychain_items_among_a_collection_of_apps)
    /// for more information.
    /// - Parameter keychainGroup: The keychain group the item must be part of.
    /// - Returns: A new instance of it's own type
    func containedIn(keychainGroup: String) -> Self {
        guard !keychainGroup.isEmpty else {
            return self
        }

        var copy = self
        copy.query[kSecAttrAccessGroup as String] = keychainGroup
        return copy
    }

    /// Set the string matching options for the keychain query.
    /// - Parameter options: Which options to set
    /// - Returns: A new instance of it's own type
    func stringMatching(options: KeychainStringComparisonOptions) -> Self {
        var copy = self
        if options.contains(.caseInsensitive) {
            copy.query[kSecMatchCaseInsensitive as String] = true
        }

#if os(macOS)
        if options.contains(.diacriticInsensitive) {
            copy.query[kSecMatchDiacriticInsensitive as String] = true
        }
        if options.contains(.widthInsensitive) {
            copy.query[kSecMatchWidthInsensitive as String] = true
        }
#endif

        return copy
    }

    internal func processSingleItem(item: CFTypeRef?, hasRef: Bool, hasData: Bool,
                                    hasPersistentRef: Bool, hasAttrs: Bool) -> Entity? {
        if CFArrayGetTypeID() == CFGetTypeID(item) {
            // We are only expecting a single entity here; an array is a problem.
            return nil
        } else if CFDictionaryGetTypeID() == CFGetTypeID(item) {
            if let dict = (item as? NSDictionary) {
                return Entity(from: hasRef ? dict[kSecValueRef] as? Entity.SecurityFrameworkType : nil,
                              data: hasData ? dict[kSecValueData] as? Data : nil,
                              attributes: hasAttrs ? dict as? [String: Any] : nil,
                              persistentRef: hasPersistentRef ? dict[kSecValuePersistentRef] as? Data : nil)
            }
        } else {
            if hasRef {
                return Entity(from: item as? Entity.SecurityFrameworkType, data: nil,
                              attributes: nil, persistentRef: nil)
            } else if hasData {
                return Entity(from: nil, data: item as? Data, attributes: nil, persistentRef: nil)
            } else if hasPersistentRef {
                return Entity(from: nil, data: nil, attributes: nil, persistentRef: item as? Data)
            }
            // NOTE: missing `hasAttrs` case because that will always return as a dictionary
            // which will fall into the dictionary processing above.
        }
        return nil
    }
}

// MARK: - macOS Only

#if os(macOS)
public extension KeychainQuerying {
    /// Matches items only in the given keychain file.
    ///
    /// Haversack usage is to specify the keychain file as part of the `HaversackConfiguration`
    /// which means this method is not part of the public API.
    /// - Important: Available on macOS only.
    /// - Parameter keychain: The keychain file to use.
    /// - Returns: A new instance of it's own type.
    internal func `in`(keychain: SecKeychain?) -> Self {
        guard let actualKeychain = keychain else {
            return self
        }

        var copy = self
        copy.query[kSecMatchSearchList as String] = [actualKeychain]
        return copy
    }
}
#endif
