// SPDX-License-Identifier: MIT
// Copyright 2023, Jamf

import Foundation

/// Matching filters that search cryptographic key metadata for identities and keys.
///
/// Used by both ``IdentityQuery`` and ``KeyQuery`` types.
public protocol KeyBaseQuerying: KeychainQuerying {
    /// Matching only keys found in the SecureEnclave.
    /// - Returns: A `KeyQuery` struct
    func inSecureEnclave() -> Self

    /// Matching based on how the key may be used.
    /// - Parameter keyUsage: A set of key usage values.
    /// - Returns: A `KeyQuery` struct
    func matching(keyUsage: KeyUsagePolicy) -> Self
}

extension KeyBaseQuerying {
    /// Matching only keys found in the SecureEnclave.
    /// - Returns: A `KeyQuery` struct
    public func inSecureEnclave() -> Self {
        var copy = self
        copy.query[kSecAttrTokenID as String] = kSecAttrTokenIDSecureEnclave
        return copy
    }

    /// Matching based on how the key may be used.
    /// - Parameter keyUsage: A set of key usage values.
    /// - Returns: A `KeyQuery` struct
    public func matching(keyUsage: KeyUsagePolicy) -> Self {
        var copy = self
        keyUsage.securityFrameworkKeyArray.forEach { (dictionaryKey) in
            copy.query[dictionaryKey as String] = true
        }
        return copy
    }
}

/// Encapsulates how cryptographic keys may be used.
public struct KeyUsagePolicy: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let canEncrypt    = KeyUsagePolicy(rawValue: 1 << 0)
    public static let canDecrypt    = KeyUsagePolicy(rawValue: 1 << 1)
    public static let canDerive     = KeyUsagePolicy(rawValue: 1 << 2)
    public static let canSign       = KeyUsagePolicy(rawValue: 1 << 3)
    public static let canVerify     = KeyUsagePolicy(rawValue: 1 << 4)
    public static let canWrap       = KeyUsagePolicy(rawValue: 1 << 5)
    public static let canUnwrap     = KeyUsagePolicy(rawValue: 1 << 6)

    /// The default usage of a public key includes encryption, deriving other keys, and verifying digital signatures.
    public static let defaultPublicKey: KeyUsagePolicy = [.canEncrypt, .canDerive, .canVerify]

    /// The default usage of a private key includes decryption, digital signing, deriving other keys, and unwrapping other keys.
    public static let defaultPrivateKey: KeyUsagePolicy = [.canDecrypt, .canDerive, .canSign, .canUnwrap]

    var securityFrameworkKeyArray: [CFString] {
        var result = [CFString]()
        if self.contains(.canEncrypt) {
            result.append(kSecAttrCanEncrypt)
        }
        if self.contains(.canDecrypt) {
            result.append(kSecAttrCanDecrypt)
        }
        if self.contains(.canDerive) {
            result.append(kSecAttrCanDerive)
        }
        if self.contains(.canSign) {
            result.append(kSecAttrCanSign)
        }
        if self.contains(.canVerify) {
            result.append(kSecAttrCanVerify)
        }
        if self.contains(.canWrap) {
            result.append(kSecAttrCanWrap)
        }
        if self.contains(.canUnwrap) {
            result.append(kSecAttrCanUnwrap)
        }
        return result
    }

    static func make(from securityFrameworkValue: SecurityFrameworkQuery) -> KeyUsagePolicy {
        var result = KeyUsagePolicy()
        if let canEncrypt = securityFrameworkValue[kSecAttrCanEncrypt as String] as? Bool, canEncrypt {
            result.update(with: .canEncrypt)
        }
        if let canDecrypt = securityFrameworkValue[kSecAttrCanDecrypt as String] as? Bool, canDecrypt {
            result.update(with: .canDecrypt)
        }
        if let canDerive = securityFrameworkValue[kSecAttrCanDerive as String] as? Bool, canDerive {
            result.update(with: .canDerive)
        }
        if let canSign = securityFrameworkValue[kSecAttrCanSign as String] as? Bool, canSign {
            result.update(with: .canSign)
        }
        if let canVerify = securityFrameworkValue[kSecAttrCanVerify as String] as? Bool, canVerify {
            result.update(with: .canVerify)
        }
        if let canWrap = securityFrameworkValue[kSecAttrCanWrap as String] as? Bool, canWrap {
            result.update(with: .canWrap)
        }
        if let canUnwrap = securityFrameworkValue[kSecAttrCanUnwrap as String] as? Bool, canUnwrap {
            result.update(with: .canUnwrap)
        }
        return result
    }
}
