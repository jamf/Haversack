// SPDX-License-Identifier: MIT
// Copyright 2023, Jamf

import Foundation
import os.log

/// Protocol to use with any type that can be converted to a [Data](https://developer.apple.com/documentation/Foundation/Data) representation.
///
/// The type can be stored in the keychain as a generic password using the ``GenericPasswordEntity`` type.
public protocol GenericPasswordConvertible {
    /// A raw representation of the thing.
    var rawRepresentation: Data { get }

    /// Creates something from a raw representation.
    static func make(fromRaw rawRepresentation: Data) throws -> Self
}

// MARK: - storage

extension GenericPasswordEntity {

    /// Attempt to make a ``GenericPasswordEntity`` from any ``GenericPasswordConvertible`` type.
    /// > Tip: In order to persist the value to the keychain, one of the Haversack `save()` methods should be called
    /// with the initialized ``GenericPasswordEntity``.
    /// - Parameter convertible: Any type that can be converted to plain [Data](https://developer.apple.com/documentation/Foundation/Data)
    public convenience init<T: GenericPasswordConvertible>(_ convertible: T) {
        self.init(from: nil, data: convertible.rawRepresentation, attributes: nil, persistentRef: nil)
    }

    /// Converts the loaded `passwordData` into another type that conforms to ``GenericPasswordConvertible``.
    ///
    /// - Important: Make sure that the type of the thing that you try to create here matches the type of
    /// the thing originally stored in the keychain.
    /// - Returns: An instance of a type that the generic password was originally created with.
    /// - Throws: An `HaversackError.notPossible` if the `passwordData` field of this entity is `nil`.  May throw
    /// an `NSError` if the data in the password cannot be used to create the requested type.  This would usually be due
    /// to a type mismatch such as storing something of one type and trying to create something of a different type from it.
    public func originalEntity<T: GenericPasswordConvertible>() throws -> T {
        guard let theData = passwordData else {
            os_log("Cannot convert to original entity of type %{public}@ because data has not been loaded",
                   log: Logs.search, type: .error, String(describing: T.self))
            throw HaversackError.notPossible("Cannot convert to original entity of type \(T.self) because data has not been loaded")
        }

        return try T.make(fromRaw: theData)
    }
}
