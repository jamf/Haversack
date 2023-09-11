// SPDX-License-Identifier: MIT
// Copyright 2023, Jamf

import Foundation

/// Represents a keychain item that can be exported from the keychain
public protocol KeychainExportable: KeychainStorable {}

/// Represents a keychain item that can be imported into a keychain
public protocol KeychainImportable: KeychainStorable {}

/// Represents a keychain item that can both be imported and exported
public typealias KeychainPortable = KeychainExportable & KeychainImportable
