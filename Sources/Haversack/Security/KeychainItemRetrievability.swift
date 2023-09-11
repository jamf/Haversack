// SPDX-License-Identifier: MIT
// Copyright 2023, Jamf

import Foundation

/// A typesafe way to specify when a keychain item is available for use.
public enum KeychainItemRetrievability: Equatable {
    /// Specify when the keychain item is available
    ///
    /// See [Apple: Restricting Keychain Item Accessibility](https://developer.apple.com/documentation/security/keychain_services/keychain_items/restricting_keychain_item_accessibility)
    /// for more information.
    /// - Note: Uses `kSecAttrAccessible`
    case simple(RetrievabilityLevel)

    /// Specify when the keychain item is available as well as additional controls.
    ///
    /// See [Apple: Restricting Keychain Item Accessibility](https://developer.apple.com/documentation/security/keychain_services/keychain_items/restricting_keychain_item_accessibility)
    /// for more information on `SecAccessControlCreateFlags`
    /// - Note: Uses `kSecAttrAccessControl`
    /// - Important: `.complex()` does not work with certificates/identities on macOS.  If you try to
    /// use it Haversack will throw a ``HaversackError/notPossible(_:)`` error from
    /// ``Haversack/Haversack/save(_:itemSecurity:updateExisting:)-5zo28``
    /// and
    /// ``Haversack/Haversack/save(_:itemSecurity:updateExisting:completionQueue:completion:)`` calls.
    case complex(RetrievabilityLevel, SecAccessControlCreateFlags)

    var securityFrameworkKey: String {
        switch self {
        case .simple:
            return kSecAttrAccessible as String
        default:
            return kSecAttrAccessControl as String
        }
    }

    func securityFrameworkValue() throws -> Any {
        switch self {
        case .simple(let retrievability):
            return retrievability.securityFrameworkKey

        case .complex(let retrievability, let flags):
            var possibleError: Unmanaged<CFError>?
            let access = SecAccessControlCreateWithFlags(nil, retrievability.securityFrameworkKey,
                                                         flags, &possibleError)
            if let result = access {
                return result
            }

            if let error = possibleError {
                throw error.takeRetainedValue()
            }
            throw HaversackError.unknownError
        }
    }
}
