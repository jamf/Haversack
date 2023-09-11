// SPDX-License-Identifier: MIT
// Copyright 2023, Jamf

import Foundation

/// The configuration of how to communicate with the keychain.
///
/// Must contain a serial queue; a default queue is created with `.userInitiated`
/// priority if one is not given in the constructor.
/// On macOS, this contains the information on which legacy keychain file to use if not
/// using the standard login keychain.
///
/// Note that if a different queue is specified, all instances of ``Haversack/Haversack`` should be initialized with
/// the same queue so that all keychain access is done atomically.
public struct HaversackConfiguration {
    /// The `DispatchQueue` to use in order to serialize all keychain access
    ///
    /// If not otherwise specified, a default serial queue will be created with the label "com.jamf.haversack".
    public let serialQueue: DispatchQueue

    /// The strategy to use for making keychain calls.
    public let strategy: HaversackStrategy

#if os(macOS)
    /// The keychain file to use.  Default is to use the user's login keychain.
    ///
    /// macOS only.
    public let keychain: KeychainFile?
#endif

#if os(macOS)

    public init(queue: DispatchQueue? = nil, strategy: HaversackStrategy? = nil,
                keychain: KeychainFile? = nil) {
        if let givenQueue = queue {
            serialQueue = givenQueue
        } else {
            serialQueue = DispatchQueue(label: "com.jamf.haversack",
                                        qos: .userInitiated, autoreleaseFrequency: .workItem,
                                        target: .global(qos: .userInitiated))
        }

        if let givenStrategy = strategy {
            self.strategy = givenStrategy
        } else {
            self.strategy = HaversackStrategy()
        }

        self.keychain = keychain
    }

#else

    public init(queue: DispatchQueue? = nil, strategy: HaversackStrategy? = nil) {
        if let givenQueue = queue {
            serialQueue = givenQueue
        } else {
            serialQueue = DispatchQueue(label: "com.jamf.haversack",
                                        qos: .userInitiated, autoreleaseFrequency: .workItem,
                                        target: .global(qos: .userInitiated))
        }

        if let givenStrategy = strategy {
            self.strategy = givenStrategy
        } else {
            self.strategy = HaversackStrategy()
        }
    }

#endif
}
