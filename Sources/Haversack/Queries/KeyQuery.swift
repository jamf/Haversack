// SPDX-License-Identifier: MIT
// Copyright 2023, Jamf

import Foundation

/// Fluent interface for searching the keychain for cryptographic keys.
///
/// Successful searches produce ``KeyEntity`` objects.
public struct KeyQuery: KeyBaseQuerying {
    public typealias Entity = KeyEntity

    public var query: SecurityFrameworkQuery

    /// Create a ``KeyQuery`` instance
    /// - Parameter label: The keychain label of the item.  Uses `kSecAttrLabel`.
    public init(label: String = "") {
        if label.isEmpty {
            query = [kSecClass as String: kSecClassKey]
        } else {
            query = [kSecClass as String: kSecClassKey,
                     kSecAttrLabel as String: label]
        }
    }

    /// Matching based on the "class" of the key.
    /// - Parameter keyClass: The keys class; `.public`, `.private` or `.symmetric`
    /// - Returns: A `KeyQuery` struct
    public func matching(keyClass: KeyClass) -> Self {
        var copy = self
        copy.query[kSecAttrKeyClass as String] = keyClass.securityFrameworkValue()
        return copy
    }

    /// Match by type of key (elliptic curve, RSA, etc).
    /// - Parameter keyAlgorithm: The type of key to search for
    /// - Returns: A `KeyQuery` struct
    public func matching(keyAlgorithm: KeyAlgorithm) -> Self {
        var copy = self
        copy.query[kSecAttrKeyType as String] = keyAlgorithm.securityFrameworkKey
        return copy
    }

    /// Matching based on the actual number of bits for the key.
    /// - Parameter keySizeInBits: The key size in bits; must be greater than zero.
    /// - Returns: A `KeyQuery` struct
    public func matching(keySizeInBits: Int) -> Self {
        guard keySizeInBits > 0 else {
            return self
        }

        var copy = self
        copy.query[kSecAttrKeySizeInBits as String] = keySizeInBits
        return copy
    }

    /// Matching based on the effective number of bits for the key.
    /// - Parameter effectiveKeySize: The effective key size in bits; must be greater than zero.
    /// - Returns: A `KeyQuery` struct
    public func matching(effectiveKeySize: Int) -> Self {
        guard effectiveKeySize > 0 else {
            return self
        }

        var copy = self
        copy.query[kSecAttrEffectiveKeySize as String] = effectiveKeySize
        return copy
    }

    /// Matching based on the tag associated with the key.
    /// - Parameter tag: Any data associated with the key
    /// - Returns: A `KeyQuery` struct
    public func matching(tag: Data) -> Self {
        guard !tag.isEmpty else {
            return self
        }

        var copy = self
        copy.query[kSecAttrApplicationTag as String] = tag
        return copy
    }

    /// Matching based on the application-specific label associated with the key.
    /// - Parameter appLabel: Any data associated with the key
    /// - Returns: A `KeyQuery` struct
    public func matching(appLabel: Data) -> Self {
        guard !appLabel.isEmpty else {
            return self
        }

        var copy = self
        copy.query[kSecAttrApplicationLabel as String] = appLabel
        return copy
    }

    /// Older keys may be stored with a String in their `kSecAttrApplicationLabel`
    ///
    /// Generally, this should not be used.
    /// - Parameter legacyAppLabel: The legacy application label
    /// - Returns: A `KeyQuery` struct
    public func matching(legacyAppLabel: String) -> Self {
        guard !legacyAppLabel.isEmpty else {
            return self
        }

        var copy = self
        copy.query[kSecAttrApplicationLabel as String] = legacyAppLabel
        return copy
    }
}

/// Encapsulates the cryptographic key's class (public, private, or symmetric).
public enum KeyClass {
    /// Represents a private key
    case `private`
    /// Represents a public key
    case `public`
    /// Represents a symmetric encryption/decryption key
    case symmetric

    private static let translation: [CFString: KeyClass] = [
        kSecAttrKeyClassPrivate: .private,
        kSecAttrKeyClassPublic: .public,
        kSecAttrKeyClassSymmetric: .symmetric
    ]

    static func make(from securityFrameworkValue: CFString) -> KeyClass? {
        return translation[securityFrameworkValue]
    }

    func securityFrameworkValue() -> CFString {
        return Self.translation.first(where: { $1 == self })!.key
    }
}

/// Encapsulates the algorithm a cryptographic key was generated to support.
public enum KeyAlgorithm {
    /// The key is valid for the RSA algorithm.
    case RSA
    /// The key is valid for an elliptic curve algorithm.
    case ellipticCurvePrimeRandom
#if os(macOS)
    /// The key is valid for the DSA algorithm.
    /// - Important: Available on macOS only.
    case DSA
    /// The key is valid for the AES algorithm.
    /// - Important: Available on macOS only.
    case AES
    /// The key is valid for the 3DES algorithm.
    /// - Important: Available on macOS only.
    case tripleDES
    /// The key is valid for the RC4 algorithm.
    /// - Important: Available on macOS only.
    case RC4
    /// The key is valid for the RC2 algorithm.
    /// - Important: Available on macOS only.
    case RC2
    /// The key is valid for the CAST algorithm.
    /// - Important: Available on macOS only.
    case CAST
#endif

    var securityFrameworkKey: CFString {
        switch self {
        case .RSA: return kSecAttrKeyTypeRSA
        case .ellipticCurvePrimeRandom: return kSecAttrKeyTypeECSECPrimeRandom
#if os(macOS)
        case .DSA: return kSecAttrKeyTypeDSA
        case .AES: return kSecAttrKeyTypeAES
        case .tripleDES: return kSecAttrKeyType3DES
        case .RC4: return kSecAttrKeyTypeRC4
        case .RC2: return kSecAttrKeyTypeRC2
        case .CAST: return kSecAttrKeyTypeCAST
#endif
        }
    }
}
