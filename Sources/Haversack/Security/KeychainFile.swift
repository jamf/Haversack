// SPDX-License-Identifier: MIT
// Copyright 2023, Jamf

import Foundation
import os.log

#if os(macOS)

/// A `String`-based file path for legacy keychain files on macOS.
public typealias FilePath = String

/// A function/block that provides the unencrypted plain `String` password to a keychain file on macOS.
public typealias KeychainPasswordProvider = (_ keychainPath: FilePath) -> String

/// Represents a legacy custom keychain file to use with the Security framework.
///
/// - Important: Available on macOS only.  Deprecated in macOS 12, although
/// not marked officially deprecated yet in Haversack.
///
///
/// #### Logging
/// Uses system logging with a subsystem of `com.jamf.haversack`.
/// Opening, creating, or deleting a custom keychain file is logged at `.default` level.
/// Locking/unlocking the keychain file is logged at the `.info` level.
/// All errors are logged at the `.error` level.
public class KeychainFile {
    /// The path to the system keychain that contains the globally trusted root CA certificates.
    static let rootCertificatesKeychainPath = "/System/Library/Keychains/SystemRootCertificates.keychain"

    /// An instance of ``KeychainFile`` that points at the system root certificates keychain
    public static let systemRootCertificates = KeychainFile(at: rootCertificatesKeychainPath)

    /// The path to the system keychain.
    static let systemKeychainPath = system.path

    /// An instance of ``KeychainFile`` that points at the system keychain
    public static let system: KeychainFile = {
        let legacySystemKeychainPath = "/Library/Keychains/System.keychain"
        var searchList: CFArray?
        let status = withUnsafeMutablePointer(to: &searchList) {
            SecKeychainCopyDomainSearchList(.system, UnsafeMutablePointer($0))
        }

        guard status == errSecSuccess else {
            // attempt to use traditional path, may fail later
            return KeychainFile(at: legacySystemKeychainPath)
        }

        guard let searchList = searchList as? [SecKeychain], let systemKeychain = searchList.first else {
            return KeychainFile(at: legacySystemKeychainPath)
        }

        return KeychainFile(reference: systemKeychain)
    }()

    /// The full path to the keychain file.
    public let path: FilePath

    /// A function that provides the password to the keychain file.
    let passwordProvider: KeychainPasswordProvider?

    /// A reference to the opened keychain.
    var reference: SecKeychain?

    /// Create an object representing a custom keychain file.
    /// - Parameters:
    ///   - filePath: The full path to the keychain file.
    ///   - passwordProvider: An optional function that provides the password to the keychain file.
    ///    If given, will be called whenever the pasword is needed in order to unlock the keychain.
    public init(at filePath: FilePath, passwordProvider: KeychainPasswordProvider? = nil) {
        self.path = (filePath as NSString).standardizingPath
        self.passwordProvider = passwordProvider
    }

    /// Create an instance from an existing keychain reference
    /// - Parameters:
    ///   - reference: A reference to a `SecKeychain`.
    init(reference: SecKeychain) {
        passwordProvider = nil
        self.reference = reference

        var pathLength = UInt32(PATH_MAX)
        let pathName = UnsafeMutablePointer<CChar>.allocate(capacity: Int(pathLength))
        let status = withUnsafeMutablePointer(to: &pathLength) { pathLength in
            SecKeychainGetPath(reference, pathLength, pathName)
        }

        if status == errSecSuccess {
            path = FileManager().string(withFileSystemRepresentation: pathName, length: Int(pathLength))
        } else {
            // should never happen
            path = ""
        }

        pathName.deallocate()
    }

    /// Try to open and unlock the keychain file, or create the keychain if it does not yet exist.
    /// - Throws: A ``HaversackError`` entity
    public func attemptToOpenOrCreate() throws {
        if isLocked {
            if !fileExists {
                try create()
            }
            try attemptToOpen()
        }
    }

    /// Internal function that ensures the keychain file is open and unlocked (if it exists).
    /// - Throws: A ``HaversackError`` entity
    func attemptToOpen() throws {
        if isLocked {
            if !fileExists {
                os_log("No keychain file found at path %{public}@", log: Logs.keychainFile, type: .error, path)
                throw HaversackError.noKeychainFileAtPath(path)
            }

            try open()
            try unlock()
        }
    }

    // MARK: - Open

    func open() throws {
        os_log("Attempting to open keychain at %{public}@", log: Logs.keychainFile, type: .default, path)
        let status = SecKeychainOpen(path, &reference)
        if status != errSecSuccess {
            os_log("SecKeychainOpen returned error %{public}d", log: Logs.keychainFile, type: .error, status)
            throw HaversackError.keychainError(status)
        }
    }

    // MARK: - Create and Delete

    /// Uses `FileManager.default` to determine if the keychain file exists.
    public var fileExists: Bool {
        FileManager.default.fileExists(atPath: path)
    }

    /// Create the keychain file.
    /// - Throws: A ``HaversackError`` entity on any errors
    func create() throws {
        // We can't create the system keychains; they should already be created always.
        guard path != KeychainFile.systemKeychainPath
                && path != KeychainFile.rootCertificatesKeychainPath else {
            return
        }

        guard let passwordFunc = passwordProvider else {
            os_log("Keychain password required to create a custom keychain but not given",
                log: Logs.keychainFile, type: .error)
            throw HaversackError.customKeychainPasswordRequired("create")
        }

        let rawPassword = passwordFunc(path)

        os_log("Attempting to create keychain at %{public}@", log: Logs.keychainFile, type: .default, path)
        let status = SecKeychainCreate(path, UInt32(rawPassword.count), rawPassword, false, nil, &reference)
        if status != errSecSuccess {
            os_log("SecKeychainCreate returned error %{public}d", log: Logs.keychainFile, type: .error, status)
            throw HaversackError.keychainError(status)
        }
    }

    /// Delete the keychain file.
    /// - Throws: A ``HaversackError`` entity on any errors
    public func delete() throws {
        os_log("Attempting to delete keychain at %{public}@", log: Logs.keychainFile, type: .default, path)
        let status = SecKeychainDelete(reference)
        if status != errSecSuccess {
            os_log("SecKeychainDelete returned error %{public}d", log: Logs.keychainFile, type: .error, status)
            throw HaversackError.keychainError(status)
        }
    }

    // MARK: - Lock and Unlock

    /// The locked/unlocked state that Haversack knows about the keychain.
    public var isLocked: Bool {
        guard let keychain = reference else {
            return true
        }

        var rawStatus: SecKeychainStatus = .zero
        let status = SecKeychainGetStatus(keychain, &rawStatus)
        if status == errSecSuccess {
            let keychainStatus = KeychainStatusOptions(rawValue: rawStatus)
            return !keychainStatus.contains(.unlocked)
        }

        return true
    }

    /// Lock the previously unlocked keychain.
    /// - Throws: A ``HaversackError`` entity on any errors
    ///
    /// After a keychain file is locked, you can call ``unlock()`` to make the items in it available for use.
    public func lock() throws {
        guard let keychain = reference else {
            os_log("Attempting to lock a keychain that has not been opened", log: Logs.keychainFile, type: .error)
            throw HaversackError.noKeychainReference
        }

        os_log("Attempting to lock keychain at %{public}@", log: Logs.keychainFile, type: .info, path)
        let status = SecKeychainLock(keychain)
        if status != errSecSuccess {
            os_log("SecKeychainLock returned error %{public}d", log: Logs.keychainFile, type: .error, status)
            throw HaversackError.keychainError(status)
        }
    }

    /// Unlock the previously locked keychain.
    /// - Throws: A ``HaversackError`` entity on any errors
    ///
    /// Generally only needed if your code has called ``lock()``.
    public func unlock() throws {
        guard let keychain = reference else {
            os_log("Attempting to unlock a keychain that has not been opened", log: Logs.keychainFile, type: .error)
            throw HaversackError.noKeychainReference
        }

        let status: OSStatus
        if path == KeychainFile.systemKeychainPath
            || path == KeychainFile.rootCertificatesKeychainPath {
            // We can't unlock the system keychain with our password; prompt the user if needed.
            os_log("Attempting to unlock keychain at %{public}@", log: Logs.keychainFile, type: .info, path)
            status = SecKeychainUnlock(keychain, 0, nil, false)
        } else {
            guard let passwordFunc = passwordProvider else {
                os_log("Keychain password required to unlock a custom keychain but not given",
                    log: Logs.keychainFile, type: .error)
                throw HaversackError.customKeychainPasswordRequired("unlock")
            }

            let rawPassword = passwordFunc(path)
            os_log("Attempting to unlock keychain at %{public}@", log: Logs.keychainFile, type: .info, path)
            status = SecKeychainUnlock(keychain, UInt32(rawPassword.count), rawPassword, true)
        }
        if status != errSecSuccess {
            os_log("SecKeychainUnlock returned error %{public}d", log: Logs.keychainFile, type: .error, status)
            throw HaversackError.keychainError(status)
        }
    }
}

/// Bring the keychain status flags into a simple OptionSet.
struct KeychainStatusOptions: OptionSet {
    let rawValue: UInt32

    static let unlocked  = KeychainStatusOptions(rawValue: kSecUnlockStateStatus)
    static let readable  = KeychainStatusOptions(rawValue: kSecReadPermStatus)
    static let writable  = KeychainStatusOptions(rawValue: kSecWritePermStatus)
}

#endif
