// SPDX-License-Identifier: MIT
// Copyright 2023, Jamf

#if os(macOS)
import Foundation

/// Represents a keychain entity that has a private key component
public protocol PrivateKeyImporting {}

extension KeyEntity: PrivateKeyImporting {}

extension IdentityEntity: PrivateKeyImporting {}

#endif
