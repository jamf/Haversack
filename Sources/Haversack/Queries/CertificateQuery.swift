// SPDX-License-Identifier: MIT
// Copyright 2023, Jamf

import Foundation

/// Fluent interface for searching the keychain for certificates.
///
/// Successful searches produce ``CertificateEntity`` objects.
public struct CertificateQuery {
    public var query: SecurityFrameworkQuery

    /// Create an ``CertificateQuery`` instance
    /// - Parameter label: The keychain label of the item.  Uses `kSecAttrLabel`.
    public init(label: String = "") {
        if label.isEmpty {
            query = [kSecClass as String: kSecClassCertificate]
        } else {
            query = [kSecClass as String: kSecClassCertificate,
                     kSecAttrLabel as String: label]
        }
    }
}

extension CertificateQuery: CertificateBaseQuerying {
    public typealias Entity = CertificateEntity

    /// Matching based on the type of certificate.
    ///
    /// In practice, most certificates are of type `.x509v1` so this may not be very useful.
    /// - Parameter certificateType: The type of certificate to search for.
    /// - Returns: A `CertificateQuery` struct
    public func matching(certificateType: CertificateType) -> Self {
        var copy = self
        copy.query[kSecAttrCertificateType as String] = certificateType.securityFrameworkValue()
        return copy
    }

    /// Matching based on the encoding of the certificate.
    ///
    /// In practice, most certificates are encoded as `.der` so this may not be very useful.
    /// - Parameter certificateEncoding: The encoding of the certificate to search for.
    /// - Returns: A `CertificateQuery` struct
    public func matching(certificateEncoding: CertificateEncoding) -> Self {
        var copy = self
        copy.query[kSecAttrCertificateEncoding as String] = certificateEncoding.securityFrameworkValue()
        return copy
    }
}

/// Specifies the type of a certificate.
///
/// Based on `CSSM_CERT_TYPE`.  Used with the `kSecAttrCertificateType` attribute of certificates.
public enum CertificateType: Int32 {
    case unknown = 0
    case x509v1 = 0x01
    case x509v2 = 0x02
    case x509v3 = 0x03
    case pgp = 0x04
    case spki = 0x05
    case sdsiv1 = 0x06
    case intel = 0x08
    case x509attribute = 0x09
    case x9attribute = 0x0A
    case tuple = 0x0B
    case aclEntry = 0x0C
    case multiple = 0x7FFE

    static func make(from securityFrameworkValue: Int32) -> Self? {
        return Self(rawValue: securityFrameworkValue)
    }

    func securityFrameworkValue() -> Int32 {
        return self.rawValue
    }
}

/// Specifies how a certificate is encoded.
///
/// Based on `CSSM_CERT_ENCODING`.  Used with the `kSecAttrCertificateEncoding` attribute of certificates.
public enum CertificateEncoding: Int32 {
    case unknown = 0
    case custom = 0x01
    case ber = 0x02
    case der = 0x03
    case ndr = 0x04
    case sexpr = 0x05
    case pgp = 0x06
    case multiple = 0x7FFE

    static func make(from securityFrameworkValue: Int32) -> Self? {
        return Self(rawValue: securityFrameworkValue)
    }

    func securityFrameworkValue() -> Int32 {
        return self.rawValue
    }
}
