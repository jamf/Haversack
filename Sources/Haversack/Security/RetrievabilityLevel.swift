// SPDX-License-Identifier: MIT
// Copyright 2023, Jamf

import Foundation

/// Specifies when a keychain item can be retrieved for use.
///
/// The name was chosen to express when items can be retrieved for use, and to stay well away from
/// the accessibility APIs that are used for user experience accommodations.
/// - Note: This is a wrapper around the `kSecAttrAccessible...` constants.  Haversack does not
/// support the deprecated "always available" levels because they provide no security.
public enum RetrievabilityLevel: CaseIterable, Equatable {
    /// Retrievable when the device is unlocked; will synchronize to iCloud Keychain and other devices.
    ///
    /// Recommended for standard user applications without background processing.
    case unlocked
    /// Retrievable when the device is unlocked; will **not** synchronize to iCloud Keychain or other devices;
    /// not included in device backups.
    ///
    /// Recommended for standard user applications without background processing.
    case unlockedThisDeviceOnly
    /// The device must have a passcode set; retrievable when the device is unlocked; will **not** synchronize
    /// to iCloud Keychain or other devices; not included in device backups.
    ///
    /// Recommended for standard user applications without background processing.  If the device passcode is removed,
    /// items with this security level will be deleted.
    case unlockedPasscodeSetThisDeviceOnly

    /// Retrievable any time after the device has been unlocked once after a restart; will synchronize to iCloud
    /// Keychain and other devices.
    ///
    /// Recommended for applications that need background usage even when the device is locked.
    case afterFirstUnlock
    /// Retrievable any time after the device has been unlocked once after a restart; will **not** synchronize
    /// to iCloud Keychain or other devices; not included in device backups.
    ///
    /// Recommended for applications that need background usage even when the device is locked.
    case afterFirstUnlockThisDeviceOnly

    /// Read only.  Whether the security level allows syncing over iCloud Keychain.
    public var synchronizable: Bool {
        return self == .unlocked || self == .afterFirstUnlock
    }

    var securityFrameworkKey: CFString {
        switch self {
        case .unlocked: return kSecAttrAccessibleWhenUnlocked
        case .unlockedThisDeviceOnly: return kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        case .unlockedPasscodeSetThisDeviceOnly: return kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly

        case .afterFirstUnlock: return kSecAttrAccessibleAfterFirstUnlock
        case .afterFirstUnlockThisDeviceOnly: return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        }
    }
}
