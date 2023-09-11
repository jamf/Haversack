// SPDX-License-Identifier: MIT
// Copyright 2023, Jamf

import Foundation

/// Options for what type of data to return from a keychain query.
public struct KeychainDataOptions: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// Get the metadata attributes for the item.
    public static let attributes           = KeychainDataOptions(rawValue: 1 << 0)
    /// Get the raw unencrypted data for the item.
    ///
    /// Using this will generate a user prompt on macOS if the data exists but your app does not have access to it.
    public static let data                 = KeychainDataOptions(rawValue: 1 << 1)
    /// Get a persistent reference that can be stored outside of the keychain.
    public static let persistantReference  = KeychainDataOptions(rawValue: 1 << 2)
    /// Get a reference to the keychain item.
    public static let reference            = KeychainDataOptions(rawValue: 1 << 3)

    /// Typically most apps will just want to read the secure data.
    public static let `default`: KeychainDataOptions = [.data]

    /// Get all of the possible data about the keychain item.
    public static let all: KeychainDataOptions = [.attributes, .data, .persistantReference, .reference]
}

/// Options for how to compare strings in keychain queries.
public struct KeychainStringComparisonOptions: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// Compare strings without caring about the case of letters.
    public static let caseInsensitive      = KeychainStringComparisonOptions(rawValue: 1 << 0)

#if os(macOS)
    /// Compare strings without caring about diacritical marks on letters; macOS only.
    /// - Important: Available on macOS only.
    public static let diacriticInsensitive = KeychainStringComparisonOptions(rawValue: 1 << 1)

    /// Compare strings without caring about ASCII/UTF8/UTF16 encoding differences; macOS only.
    /// - Important: Available on macOS only.
    public static let widthInsensitive     = KeychainStringComparisonOptions(rawValue: 1 << 2)
#endif
}
