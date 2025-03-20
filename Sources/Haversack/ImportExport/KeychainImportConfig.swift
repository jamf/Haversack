// SPDX-License-Identifier: MIT
// Copyright 2023, Jamf

import Foundation

#if os(macOS)
/// Used with ``Haversack`` to import Keychain items
///
/// Create a `KeychainImportConfig` and specify what type of keychain item you're importing,
/// then pass it to ``Haversack/Haversack/importItems(_:config:)``
public struct KeychainImportConfig<T: KeychainImportable> {
    public typealias ImportedEntity = T

    // MARK: Public
    public init() {}

    // MARK: SecItemImport parameters
    /// The name or extension of the file from which the external representation was previously read.
    /// This serves as a hint for the key format and key type detection code.
    /// - Parameter nameOrExtension: The name or extension of the file that the data being imported was read from.
    /// - Returns: A `KeychainImportConfig` struct
    public func fileNameOrExtension(_ nameOrExtension: String) -> Self {
        var copy = self
        copy.fileNameOrExtension = nameOrExtension as CFString

        return copy
    }

    /// Set the format of the data being imported
    ///
    /// If you know what format the external representation is in, set the initial value of this variable to an appropriate format constant to eliminate the need to detect the format.
    /// If not, set it to `SecExternalFormat.formatUnknown.`
    /// - Parameter format: The format of the data being imported
    /// - Returns: A `KeychainImportConfig` struct
    public func inputFormat(_ format: SecExternalFormat) -> Self {
        var copy = self
        copy.inputFormat = format

        return copy
    }

    /// Set the type of security item being imported
    ///
    /// Before calling this function, if you know what type of key the external representation contains, set the variable to an appropriate type constant to eliminate the need to
    /// detect the key type. If not, set it to `SecExternalItemType.itemTypeUnknown`.
    /// - Parameter type: The type of security item you intend to import with this configuration
    /// - Returns: A `KeychainImportConfig` struct
    public func itemType(_ type: SecExternalItemType) -> Self {
        var copy = self
        copy.itemType = type

        return copy
    }

    /// Specifies that you do NOT want to have the items being imported saved to the keychain
    /// - Returns: A `KeychainImportConfig` struct
    public func returnEntitiesWithoutSaving() throws -> Self {
        guard
            isSensitive == nil,
            isExtractable == nil,
            accessRef == nil,
            !keyImportFlags.contains(.importOnlyOne),
            !keyImportFlags.contains(.noAccessControl)
        else {
            // swiftlint:disable:next line_length
            throw HaversackError.notPossible("You can't return entities without saving if import flags are configured. Try removing `mustBeEncryptedDuringExport`, `extractable`, `privateKeyAccessRef`, or the `importOnlyOne` and `noAccessControl` flags in `keyImportFlags` if you don't want to import these items to a keychain")
        }

        var copy = self
        copy.shouldImportIntoKeychain = false

        return copy
    }

    // MARK: Private key import settings
    /// Specifies the initial access controls of imported private keys.
    /// - Parameter ref: The access controls the imported item should have
    /// - Returns: A `KeychainImportConfig` struct
    public func privateKeyAccessRef(_ ref: SecAccess) throws -> Self where T: PrivateKeyImporting {
        // swiftlint:disable:next line_length
        try assertImportingIntoKeychain(errorMessage: "You can't specify access controls of imported keys if you're not importing to a keychain. Try removing `returnEntitiesWithoutSaving` if you want to set the access controls of this item")
        var copy = self
        copy.accessRef = ref

        return copy
    }

    /// Only import a single private key
    /// - Returns: A `KeychainImportConfig` struct
    public func importOnlyOne() throws -> Self where T: PrivateKeyImporting {
        // swiftlint:disable:next line_length
        try assertImportingIntoKeychain(errorMessage: "Entities can't have the importOnlyOne flag if they're not being saved to the keychain. Try removing `returnEntitiesWithoutSaving` if you want to set these flags")

        var copy = self
        copy.keyImportFlags = copy.keyImportFlags.union(.importOnlyOne)

        return copy
    }

    /// Import the private keys without an access object attached
    /// - Returns: A `KeychainImportConfig` struct
    public func noAccessControl() throws -> Self where T: PrivateKeyImporting {
        // swiftlint:disable:next line_length
        try assertImportingIntoKeychain(errorMessage: "Entities can't have the noAccessControl flag if they're not being saved to the keychain. Try removing `returnEntitiesWithoutSaving` if you want to set these flags")

        var copy = self
        copy.keyImportFlags = copy.keyImportFlags.union(.noAccessControl)

        return copy
    }

    /// Require any imported keys to be encrypted before being exported
    /// - Returns: A `KeychainImportConfig` struct
    public func mustBeEncryptedDuringExport() throws -> Self where T: PrivateKeyImporting {
        // swiftlint:disable:next line_length
        try assertImportingIntoKeychain(errorMessage: "Keys cannot be marked as sensitive if they're not being imported into a keychain. Try removing `returnEntitiesWithoutSaving` if you want to set this flag")

        var copy = self
        copy.isSensitive = true

        return copy
    }

    /// Make any imported keys extractable. By default keys are not extractable after import
    /// - Returns: A `KeychainImportConfig` struct
    public func extractable() throws -> Self where T: PrivateKeyImporting {
        // swiftlint:disable:next line_length
        try assertImportingIntoKeychain(errorMessage: "Keys cannot be marked extractable if they're not being imported into a keychain. Try removing `returnEntitiesWithoutSaving` if you want to set this flag")

        var copy = self
        copy.isExtractable = true

        return copy
    }

    /// An array containing usage attributes applied to a key on import.
    /// - Parameter usage: A `KeyUsagePolicy` object describing the intended uses of the item being imported
    /// - Returns: A `KeychainImportConfig` struct
    public func usage(_ usage: KeyUsagePolicy) -> Self where T: PrivateKeyImporting {
        var copy = self
        copy.keyUsage = usage

        return copy
    }

    /// Set the strategy for acquiring the passphrase to decrypt the data being imported
    /// - Parameter strategy: The strategy to use for obtaining the passphrase
    /// - Returns: A `KeychainExportConfig` struct
    public func passphraseStrategy(_ strategy: PassphraseStrategy) -> Self where T: PrivateKeyImporting {
        var copy = self

        switch strategy {
        case .promptUser(let prompt, let title):
            copy.keyImportFlags.insert(.securePassphrase)
            copy.alertPrompt = prompt as CFString
            copy.alertTitle = title as CFString
        case .useProvided(let provider):
            copy.passphraseProvider = provider
        }

        return copy
    }

    // MARK: Internal
    // SecItemImport parameters
    var fileNameOrExtension: CFString?
    var inputFormat: SecExternalFormat = .formatUnknown
    var itemType: SecExternalItemType = .itemTypeUnknown
    var secItemImportFlags = SecItemImportExportFlags()
    var shouldImportIntoKeychain = true

    // SecItemImportExportKeyParameters
    var accessRef: SecAccess?
    var keyUsage: KeyUsagePolicy?
    var passphraseProvider: (() -> String)?
    var keyImportFlags = SecKeyImportExportFlags()
    var alertPrompt: CFString?
    var alertTitle: CFString?
    var isExtractable: Bool?
    var isPermanent: Bool?
    var isSensitive: Bool?

    var keyParams: SecItemImportExportKeyParameters {
        var params = SecItemImportExportKeyParameters()
        params.version = UInt32(SEC_KEY_IMPORT_EXPORT_PARAMS_VERSION)
        params.flags = keyImportFlags

        if let accessRef = accessRef {
            params.accessRef = Unmanaged.passRetained(accessRef)
        }

        if let keyAttributes = keyAttributes {
            params.keyAttributes = Unmanaged.passRetained(keyAttributes)
        }

        if let keyUsage = keyUsage {
            params.keyUsage = Unmanaged.passRetained(keyUsage.securityFrameworkKeyArray as CFArray)
        }

        if let passphraseProvider = passphraseProvider {
            params.passphrase = Unmanaged.passRetained(passphraseProvider() as CFString)
        }

        if let alertTitle = alertTitle {
            params.alertTitle = Unmanaged.passRetained(alertTitle as CFString)
        }

        if let alertPrompt = alertPrompt {
            params.alertPrompt = Unmanaged.passRetained(alertPrompt as CFString)
        }

        return params
    }

    /// An array containing zero or more key attributes for an imported key.
    ///
    /// Valid values are kSecAttrIsPermanent, kSecAttrIsSensitive, and kSecAttrIsExtractable. If you set this attribute array to NULL, the following defaults are used:
    /// - The item is marked permanent if a keychain is specified.
    /// - The item is marked sensitive if it is a private key.
    /// - The item is marked extractable by default.
    var keyAttributes: CFArray? {
        var attrs = [CFString]()
        if let isSensitive = isSensitive, isSensitive {
            attrs.append(kSecAttrIsSensitive)
        }

        if shouldImportIntoKeychain {
            attrs.append(kSecAttrIsPermanent)
        }

        if let isExtractable = isExtractable, isExtractable {
            attrs.append(kSecAttrIsExtractable)
        }

        var returnOnEmpty: CFArray?
        if isSensitive != nil || isPermanent != nil || isExtractable != nil {
            // If we didn't need to add any attributes but a value was provided, we need to return
            // an empty array to override the default behaviors described in this variable's discussion
            returnOnEmpty = NSArray() as CFArray
        }

        // If no attributes were specified, supplying nil will use the default values
        return attrs.isEmpty ? returnOnEmpty : attrs as CFArray
    }

    // MARK: Private
    private func assertImportingIntoKeychain(errorMessage: String) throws {
        if !shouldImportIntoKeychain {
            throw HaversackError.notPossible(errorMessage)
        }
    }
}

#endif
