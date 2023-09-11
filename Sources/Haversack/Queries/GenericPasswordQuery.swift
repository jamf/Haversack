// SPDX-License-Identifier: MIT
// Copyright 2023, Jamf

import Foundation

/// Fluent interface for searching the keychain for generic passwords.
///
/// Successful searches produce ``GenericPasswordEntity`` objects.
public struct GenericPasswordQuery {
    public var query: SecurityFrameworkQuery

    /// Create a GenericPasswordQuery
    /// - Parameter service: The name of the service associated with the password
    public init(service: String = "") {
        if service.isEmpty {
            query = [kSecClass as String: kSecClassGenericPassword]
        } else {
            query = [kSecClass as String: kSecClassGenericPassword,
                     kSecAttrService as String: service]
        }
    }
}

extension GenericPasswordQuery: PasswordBaseQuerying {
    public typealias Entity = GenericPasswordEntity

    /// Matching based on custom data associated with the generic password.
    /// - Parameter customData: Any custom data that was associated with the generic password
    /// - Returns: A `GenericPasswordQuery` struct
    public func matching(customData: Data) -> Self {
        var copy = self
        copy.query[kSecAttrGeneric as String] = customData
        return copy
    }
}
