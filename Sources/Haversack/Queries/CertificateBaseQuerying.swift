// SPDX-License-Identifier: MIT
// Copyright 2023, Jamf

import Foundation

/// Matching filters that search certificate data for certificates and identities.
///
/// Used by both ``IdentityQuery`` and ``CertificateQuery`` types.
public protocol CertificateBaseQuerying: KeychainQuerying {
    /// Filter certificates/identities by email address
    /// - Parameter email: An email address
    /// - Returns: A new instance of it's own type
    func matching(email: String) -> Self

    /// Matching a certificate/identity based on it's subject contents
    /// - Parameters:
    ///   - matchType: How much of the subject must match the given string?
    ///   - subject: The string to look for in the subject info
    /// - Returns: A new instance of it's own type
    func matchingSubject(_ matchType: CertSubjectMatchType, _ subject: String) -> Self

    /// Matching a certificate/identity based on the validity dates of the certificate.
    /// - Parameter date: A given date when the identity must be valid.
    /// - Returns: A new instance of it's own type
    func matching(mustBeValidOnDate date: Date) -> Self

    /// Matching only certificates/identities that chain back to a trusted root.
    /// - Returns: A new instance of it's own type
    func trustedOnly() -> Self
}

/// Specifies how to match partial certificate subject strings during a query.
///
/// Refer to the ``KeychainQuerying/stringMatching(options:)-7t0r4`` function and
/// ``KeychainStringComparisonOptions`` enum for additional ways to modify the string matching.
public enum CertSubjectMatchType {
    /// The subject of the cert must contain the string, but may have any other prefix and/or suffix.
    ///
    /// Refer to the ``KeychainQuerying/stringMatching(options:)-7t0r4`` function and
    /// ``KeychainStringComparisonOptions`` enum for additional ways to modify the string matching.
    case contains

#if os(macOS)
    /// The subject of the cert must begin with the string, but may have any other suffix.
    ///
    /// Available on macOS only.
    case startsWith
    /// The subject of the cert must end with the string, but may have any other prefix.
    ///
    /// Available on macOS only.
    case endsWith
    /// The subject of the cert must exactly match the string.
    ///
    /// Available on macOS only.
    case isExactly
#endif

    var queryKey: String {
#if os(macOS)
        switch self {
        case .contains:
            return kSecMatchSubjectContains as String
        case .startsWith:
            return kSecMatchSubjectStartsWith as String
        case .endsWith:
            return kSecMatchSubjectEndsWith as String
        case .isExactly:
            return kSecMatchSubjectWholeString as String
        }
#else
        return kSecMatchSubjectContains as String
#endif
    }
}

extension CertificateBaseQuerying {
    /// Filter certificates/identities by email address
    /// - Parameter email: An email address
    /// - Returns: A new instance of it's own type
    public func matching(email: String) -> Self {
        guard !email.isEmpty else {
            return self
        }

        var copy = self
        copy.query[kSecMatchEmailAddressIfPresent as String] = email
        return copy
    }

    /// Matching a certificate/identity based on it's subject contents
    /// - Parameters:
    ///   - matchType: How much of the subject must match the given string?
    ///   - subject: The string to look for in the subject info
    /// - Returns: A new instance of it's own type
    public func matchingSubject(_ matchType: CertSubjectMatchType, _ subject: String) -> Self {
        guard !subject.isEmpty else {
            return self
        }

        var copy = self
        copy.query[matchType.queryKey] = subject
        return copy
    }

    /// Matching a certificate/identity based on the validity dates of the certificate.
    /// - Parameter date: A given date when the identity must be valid.
    /// - Returns: A new instance of it's own type
    public func matching(mustBeValidOnDate date: Date) -> Self {
        var copy = self
        copy.query[kSecMatchValidOnDate as String] = date as CFDate
        return copy
    }

    /// Matching only certificates/identities that chain back to a trusted root.
    /// - Returns: A new instance of it's own type
    public func trustedOnly() -> Self {
        var copy = self
        copy.query[kSecMatchTrustedOnly as String] = true
        return copy
    }
}
