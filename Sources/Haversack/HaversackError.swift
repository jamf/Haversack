// SPDX-License-Identifier: MIT
// Copyright 2023, Jamf

import Foundation

/// When Haversack runs into errors it generally throws one of these.
public enum HaversackError: Error, Equatable {
    /// The associated value is an `OSStatus` code
    case keychainError(OSStatus)
    /// After performing a search, Haversack encountered a problem converting the search results to an entity object.
    case couldNotConvertToEntity
    /// When using a custom keychain file on macOS, calling lock or unlock before opening the keychain will throw this error.
    case noKeychainReference
    /// The associated value is the developer specified path to the keychain file
    case noKeychainFileAtPath(String)
    /// Thrown when attempting to retrieve the certificate or key from an identity entity but the identity has not
    /// been loaded from the keychain yet.
    case referenceNotLoaded
    /// Attempted to do something with a custom keychain file but did not instantiate with a password provider block.
    ///
    /// The associated value is a string describing exactly what was attempted (create or unlock).
    case customKeychainPasswordRequired(String)
    /// Attempted to do something which is not possible.
    ///
    /// Haversack's type-safety handles most things, but it cannot check everything.  Additional Haversack code verifies that the
    /// combination of parameters used can actually work with the Security framework.  The associated string of the error is a
    /// message to developers with more information about what is not compatible.
    case notPossible(String)
    /// This is used when no error should be possible, but Swift code demands an error
    case unknownError
}

extension HaversackError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .keychainError(let status):
            return (SecCopyErrorMessageString(status, nil) ?? "Code: \(status)" as CFString) as String
        case .noKeychainReference:
            return NSLocalizedString("Attempting to lock/unlock a keychain that has not been opened",
                                     comment: "Err")
        case .noKeychainFileAtPath(let path):
            let format = NSLocalizedString("There was no keychain file found at path '%@'",
                                           comment: "Err")
            return String(format: format, path)
        case .referenceNotLoaded:
            return NSLocalizedString("The required keychain item reference has not been loaded",
                                     comment: "Most likely programmer error here.")
        case .customKeychainPasswordRequired(let details):
            return NSLocalizedString("A password provider must be given to the -init method in order to \(details) a custom keychain file.",
                                     comment: "Most likely programmer error.")
        case .notPossible(let reason):
            let format = NSLocalizedString("The requested action is not possible. %@",
                                           comment: "Most likely programmer error here.")
            return String(format: format, reason)
        default:
            return NSLocalizedString("Could not convert found keychain item to entity object",
                                     comment: "Err")
        }
    }
}
