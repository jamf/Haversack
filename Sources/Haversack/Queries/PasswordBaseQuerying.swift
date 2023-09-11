// SPDX-License-Identifier: MIT
// Copyright 2023, Jamf

import Foundation

/// Matching filters that search password metadata for internet passwords and generic passwords.
///
/// Used by both ``InternetPasswordQuery`` and ``GenericPasswordQuery`` types.
public protocol PasswordBaseQuerying: KeychainQuerying {
    /// Matching based on the account associated with the generic/internet password
    /// - Parameter account: An account name.
    /// - Returns: A new instance of it's own type
    func matching(account: String) -> Self

    /// Matching based on the label associated with the generic/internet password
    /// - Parameter label: A password label.
    /// - Returns: A new instance of it's own type
    func matching(label: String) -> Self

    /// Matching based on the custom group number associated with the generic/internet password.
    /// - Parameter group: An integer.
    /// - Returns: A new instance of it's own type
    func matching(group: Int) -> Self
}

public extension PasswordBaseQuerying {
    /// Matching based on the account associated with the generic/internet password
    /// - Parameter account: An account name.
    /// - Returns: A new instance of it's own type
    func matching(account: String) -> Self {
        var copy = self
        copy.query[kSecAttrAccount as String] = account
        return copy
    }

    /// Matching based on the label associated with the generic/internet password
    /// - Parameter label: A password label.
    /// - Returns: A new instance of it's own type
    func matching(label: String) -> Self {
        var copy = self
        copy.query[kSecAttrLabel as String] = label
        return copy
    }

    /// Matching based on the custom group number associated with the generic/internet password.
    /// - Parameter group: An integer.
    /// - Returns: A new instance of it's own type
    func matching(group: Int) -> Self {
        var copy = self
        copy.query[kSecAttrType as String] = group
        return copy
    }
}
