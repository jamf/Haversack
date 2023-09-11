// SPDX-License-Identifier: MIT
// Copyright 2023, Jamf

import Foundation

/// Fluent interface for searching the keychain for internet passwords.
///
/// Successful searches produce ``InternetPasswordEntity`` objects.
public struct InternetPasswordQuery {
    public var query: SecurityFrameworkQuery

    /// Create an ``InternetPasswordQuery``
    /// - Parameter server: The domain name or IP address of a server associated with the password
    public init(server: String = "") {
        if server.isEmpty {
            query = [kSecClass as String: kSecClassInternetPassword]
        } else {
            query = [kSecClass as String: kSecClassInternetPassword,
                     kSecAttrServer as String: server]
        }
    }
}

extension InternetPasswordQuery: PasswordBaseQuerying {
    public typealias Entity = InternetPasswordEntity

    /// Matching based on port number associated with the internet password.
    /// - Parameter port: A port number that was associated with the internet password
    /// - Returns: An `InternetPasswordQuery` struct
    public func matching(port: Int) -> Self {
        var copy = self
        copy.query[kSecAttrPort as String] = port
        return copy
    }
}
