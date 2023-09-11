// SPDX-License-Identifier: MIT
// Copyright 2023, Jamf

import Foundation

#if os(macOS)
/// Used with ``Haversack`` to export Keychain items
///
/// Create a `KeychainExportConfig` and pass it to ``Haversack/Haversack/exportItems(_:config:)``
public struct KeychainExportConfig {
    // MARK: Public
    public init(outputFormat: SecExternalFormat) {
        self.outputFormat = outputFormat
    }

    /// A flag that indicates the exported data should have PEM armor.
    ///
    /// Sets the `pemArmour` flag on the configuration's `SecItemImportExportFlags`
    /// - Returns: A `KeychainExportConfig` struct
    public func PEMArmored() -> Self {
        var copy = self
        copy.flags.insert(.pemArmour)

        return copy
    }

    /// Set the strategy for acquiring the passphrase to encrypt the data being exported
    /// - Parameter strategy: The strategy to use for obtaining the passphrase
    /// - Returns: A `KeychainExportConfig` struct
    public func passphraseStrategy(_ strategy: PassphraseStrategy) -> Self {
        var copy = self

        switch strategy {
        case .promptUser(let prompt, let title):
            copy.keyImportExportFlags = .securePassphrase
            copy.alertPrompt = prompt as CFString
            copy.alertTitle = title as CFString
        case .useProvided(let provider):
            copy.passphraseProvider = provider
        }

        return copy
    }

    // MARK: Internal
    var outputFormat: SecExternalFormat
    var flags = SecItemImportExportFlags()
    var keyParameters: SecItemImportExportKeyParameters {
        var params = SecItemImportExportKeyParameters()
        params.version = UInt32(SEC_KEY_IMPORT_EXPORT_PARAMS_VERSION)
        params.flags = keyImportExportFlags

        if let alertPrompt = alertPrompt {
            params.alertPrompt = Unmanaged.passRetained(alertPrompt)
        }

        if let alertTitle = alertTitle {
            params.alertTitle = Unmanaged.passRetained(alertTitle)
        }

        if let passphrase = passphraseProvider {
            params.passphrase = Unmanaged.passRetained(passphrase() as CFString)
        }

        return params
    }

    // MARK: Private
    private var alertPrompt: CFString?
    private var alertTitle: CFString?
    /// A function that provides the password to the keychain file.
    private var passphraseProvider: (() -> String)?
    private var keyImportExportFlags = SecKeyImportExportFlags()
}
#endif
