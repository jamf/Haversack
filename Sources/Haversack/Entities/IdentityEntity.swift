// SPDX-License-Identifier: MIT
// Copyright 2023, Jamf

import Foundation

/// Represents a certificate plus private key in the keychain.
public class IdentityEntity: KeychainStorable, KeychainPortable {
    /// Uses the `SecIdentity` type to interface with the Security framework.
    public typealias SecurityFrameworkType = SecIdentity

    /// The keychain item reference, if it has been returned.
    public var reference: SecurityFrameworkType?

    /// The persistent keychain item reference, if it has been returned.
    public var persistentRef: Data?

    /// The raw identity data.
    public var identityData: Data?

    /// When requesting attributes, this is filled with the certificate info from the identity; read only.
    public var certificate: CertificateEntity?

    public required init(from keychainItemRef: SecurityFrameworkType?, data: Data?,
                         attributes: [String: Any]?, persistentRef: Data?) {

        reference = keychainItemRef
        self.persistentRef = persistentRef
        identityData = data

        if let attrs = attributes {
            certificate = CertificateEntity(from: nil, data: nil, attributes: attrs, persistentRef: nil)
        }
    }

    /// Return the `SecCertificate` from the identity for use with other Security Framework APIs.
    /// - Throws: A ``HaversackError`` if any problems occur.
    /// - Returns: The `SecCertificate` related to the identity
    func getSecCertificate() throws -> SecCertificate? {
        var certificate: SecCertificate?
        if let identityRef = reference {
            let status = SecIdentityCopyCertificate(identityRef, &certificate)
            if status != errSecSuccess {
                throw HaversackError.keychainError(status)
            }
        } else {
            throw HaversackError.referenceNotLoaded
        }
        return certificate
    }

    /// Return the private key `SecKey` from the identity for use with other Security Framework APIs.
    /// - Throws: A ``HaversackError`` if any problems occur.
    /// - Returns: The `SecCertificate` related to the identity
    func getPrivateSecKey() throws -> SecKey? {
        var privateKey: SecKey?
        if let identityRef = reference {
            let status = SecIdentityCopyPrivateKey(identityRef, &privateKey)
            if status != errSecSuccess {
                throw HaversackError.keychainError(status)
            }
        } else {
            throw HaversackError.referenceNotLoaded
        }
        return privateKey
    }

    // MARK: - KeychainStorable

    public func entityQuery(includeSecureData: Bool) -> SecurityFrameworkQuery {
        var newQuery: SecurityFrameworkQuery

        if let certEntity = certificate {
            newQuery = certEntity.entityQuery(includeSecureData: false)
        } else {
            newQuery = SecurityFrameworkQuery()
        }

        newQuery[kSecClass as String] = kSecClassIdentity

        if let theReference = reference {
            newQuery[kSecValueRef as String] = theReference
        }

        if let thePersistentRef = persistentRef {
            newQuery[kSecValuePersistentRef as String] = thePersistentRef
        }

        return newQuery
    }
}
