// SPDX-License-Identifier: MIT
// Copyright 2023, Jamf

import Foundation
import OrderedCollections

/// Fluent interface for searching the keychain for identities.
///
/// An identity is a certificate plus a private key.
/// Successful searches produce ``IdentityEntity`` objects.
public struct IdentityQuery {
    public var query: SecurityFrameworkQuery

    /// Create an ``IdentityQuery`` instance
    /// - Parameter label: The keychain label of the item.  Uses `kSecAttrLabel`.
    public init(label: String = "") {
        if label.isEmpty {
            query = [kSecClass as String: kSecClassIdentity]
        } else {
            query = [kSecClass as String: kSecClassIdentity,
                     kSecAttrLabel as String: label]
        }
    }
}

extension IdentityQuery: KeyBaseQuerying {
    // Identities can be found by looking at some of their key metadata as well.
}

extension IdentityQuery: CertificateBaseQuerying {
    public typealias Entity = IdentityEntity

    /// Filter by certificate issuer; identities returned will have at least one of the `issuers` in their
    /// certificate issuer chain.
    /// - Warning: Unavailable on macOS 10.12 or earlier when using a file-based keychain (r. 9842254).
    /// - Parameter issuers: An array of dictionaries of issuer subject info; the dictionary keys are string OIDs,
    /// and the values are the certificate values for those OIDs.  The order of the OID/value pairs must match exactly
    /// the order of the actual issuer subject info.
    /// - Returns: An `IdentityQuery` struct
    public func matching(issuers: [OrderedDictionary<String, String>]) -> Self {
        guard !issuers.isEmpty else {
            return self
        }

        let queryInfo = issuers.map { (issuer) in
            Data.makeASN1EncodedName(from: issuer)
        }

        var copy = self
        copy.query[kSecMatchIssuers as String] = queryInfo
        return copy
    }

    /// Filter by certificate issuer; identities returned will have at least one of the issuers in their
    /// certificate issuer chain.
    /// - Warning: Unavailable on macOS 10.12 or earlier when using a file-based keychain (r. 9842254).
    /// - Parameter issuersData: An array of one or more raw issuer data from a certificate/identity.
    /// Easist to get from a ``CertificateEntity``'s ``CertificateEntity/issuerData`` attribute.
    /// - Returns: An `IdentityQuery` struct
    public func matching(issuersData: [Data]) -> Self {
        guard !issuersData.isEmpty else {
            return self
        }

        var copy = self
        copy.query[kSecMatchIssuers as String] = issuersData
        return copy
    }
}
