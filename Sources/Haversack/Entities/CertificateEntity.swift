// SPDX-License-Identifier: MIT
// Copyright 2023, Jamf

import Foundation
import OrderedCollections

/// Represents a certificate in the keychain.
public class CertificateEntity: KeychainStorable, KeychainPortable {
    /// Uses the `SecCertificate` type to interface with the Security framework.
    public typealias SecurityFrameworkType = SecCertificate

    /// The keychain item reference, if it has been returned.
    public var reference: SecurityFrameworkType?

    /// The persistent keychain item reference, if it has been returned.
    public var persistentRef: Data?

    /// The certificate data.
    public var certificateData: Data?

    /// A user-visible label for the item.
    /// - Note: Uses `kSecAttrLabel`
    public var label: String?

    /// The certificate usage type; read only.
    /// - Note: Uses `kSecAttrCertificateType`
    public private(set) var certType: CertificateType?

    /// The certificate encoding; read only.
    /// - Note: Uses `kSecAttrCertificateEncoding`
    public private(set) var certEncoding: CertificateEncoding?

    /// The certificate's serial number; read only.
    /// - Note: Uses `kSecAttrSerialNumber`
    public private(set) var serialNumber: Data?

    /// The certificate's public key hash
    /// - Note: Uses `kSecAttrPublicKeyHash`
    public var publicKeyHash: Data?

    /// The certificate's subject key identifier; read only.
    ///
    /// Associated with [OID 2.5.29.14](https://oidref.com/2.5.29.14) within the certificate
    /// - Note: Uses `kSecAttrSubjectKeyID`
    public var subjectKeyID: Data?

    /// The raw issuer data; read only.
    /// - Note: Uses `kSecAttrIssuer`
    public private(set) var issuerData: Data?

    /// The` issuerData` parsed into a dictionary of OIDs to names; read only.
    public private(set) var issuerStrings: OrderedDictionary<String, String>?

    /// The raw subject data; read only.
    /// - Note: Uses `kSecAttrSubject`
    public private(set) var subjectData: Data?

    /// The `subjectData` parsed into a dictionary of OIDs to names; read only.
    public private(set) var subjectStrings: OrderedDictionary<String, String>?

    public required init(from keychainItemRef: SecurityFrameworkType?, data: Data?,
                         attributes: [String: Any]?, persistentRef: Data?) {
        reference = keychainItemRef
        certificateData = data
        self.persistentRef = persistentRef

        if let attrs = attributes {
            label = attrs[kSecAttrLabel as String] as? String
            if let certTypeData = attrs[kSecAttrCertificateType as String] as? Int32 {
                certType = CertificateType.make(from: certTypeData)
            }
            if let encodingData = attrs[kSecAttrCertificateEncoding as String] as? Int32 {
                certEncoding = CertificateEncoding.make(from: encodingData)
            }
            serialNumber = attrs[kSecAttrSerialNumber as String] as? Data
            publicKeyHash = attrs[kSecAttrPublicKeyHash as String] as? Data
            subjectKeyID = attrs[kSecAttrSubjectKeyID as String] as? Data

            issuerData = attrs[kSecAttrIssuer as String] as? Data
            if let issuerInfo = issuerData {
                issuerStrings = issuerInfo.decodeASN1Names()
            }

            subjectData = attrs[kSecAttrSubject as String] as? Data
            if let subjectInfo = subjectData {
                subjectStrings = subjectInfo.decodeASN1Names()
            }
        }
    }

    /// A simple initializer to use with an existing `SecCertificate` not in the keychain.
    /// - Parameter keychainItemRef: A `SecCertificate` that is not in a keychain.
    public convenience init(from keychainItemRef: SecCertificate) {
        self.init(from: keychainItemRef, data: nil, attributes: nil, persistentRef: nil)
    }

    // MARK: - KeychainStorable

    public func entityQuery(includeSecureData: Bool) -> SecurityFrameworkQuery {
        var newQuery = SecurityFrameworkQuery()

        newQuery[kSecClass as String] = kSecClassCertificate

        if let theLabel = label {
            newQuery[kSecAttrLabel as String] = theLabel
        }

        if let theReference = reference {
            newQuery[kSecValueRef as String] = theReference
        }

        if let thePersistentRef = persistentRef {
            newQuery[kSecValuePersistentRef as String] = thePersistentRef
        }

        if let theType = certType {
            newQuery[kSecAttrCertificateType as String] = theType.securityFrameworkValue()
        }

        if let theHash = publicKeyHash {
            newQuery[kSecAttrPublicKeyHash as String] = theHash
        }

        if includeSecureData, let secureData = certificateData {
            newQuery[kSecValueData as String] = secureData
        }

        return newQuery
    }
}
