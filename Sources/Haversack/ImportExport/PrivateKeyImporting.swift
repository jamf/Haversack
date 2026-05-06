// SPDX-License-Identifier: MIT
// Copyright 2026, Jamf

#if os(macOS)
import Foundation

/// Represents a keychain entity that has a private key component
public protocol PrivateKeyImporting: Sendable {}

extension KeyEntity: PrivateKeyImporting {}

extension IdentityEntity: PrivateKeyImporting {}

#endif
