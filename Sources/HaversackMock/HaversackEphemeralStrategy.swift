// SPDX-License-Identifier: MIT
// Copyright 2023, Jamf

import Foundation
import Haversack

/// A strategy which uses a simple dictionary to search, store, and delete data instead of hitting an actual keychain.
///
/// The keys of the ``mockData`` dictionary are calculated from the queries that are sent through Haversack.
open class HaversackEphemeralStrategy: HaversackStrategy {
    /// The dictionary that is used for storage of keychain items
    ///
    /// Items can be added into or removed from this dictionary manually.
    /// > Warning: Direct access to this dictionary is not inherently safe in multi-threaded code.
    /// Haversack will only access this dictionary on the serial queue from its `HaversackConfiguration`.
    public var mockData = [String: Any]()

    #if os(macOS)
    /// The configuration that was passed to ``exportItems(_:configuration:)``
    public var exportConfiguration: KeychainExportConfig?
    /// The error that, if present, will be thrown by ``exportItems(_:configuration:)``
    public var mockExportError: Error?
    /// The data that will be returned by ``exportItems(_:configuration:)``. Defaults to an empty `Data` object
    public var mockExportedData = Data()

    /// The key import configuration, if any, that was passed to ``exportItems(_:configuration:)``
    public var keyImportConfiguration: KeychainImportConfig<KeyEntity>?
    /// The certificate import configuration, if any, that was passed to ``exportItems(_:configuration:)``
    public var certificateImportConfiguration: KeychainImportConfig<CertificateEntity>?
    /// The identity import configuration, if any, that was passed to ``exportItems(_:configuration:)``
    public var identityImportConfiguration: KeychainImportConfig<IdentityEntity>?
    /// The error that, if present, will be thrown by ``importItems(_:configuration:importKeychain:)``
    public var mockImportError: Error?
    /// The entities that will be returned by ``importItems(_:configuration:importKeychain:)``. Defaults to an empty array
    public var mockImportedEntities = [any KeychainImportable]()
    #endif

    /// If the strategy has any problems it will throw `NSError` with this domain.
    public static let errorDomain = "haversack.unit_testing.mock"

    /// Looks through the ``mockData`` dictionary for an entry matching the query.
    /// - Parameter querying: An instance of a type that conforms to the `KeychainQuerying` protocol.
    /// - Throws: An `NSError` with the ``errorDomain`` domain if no entry is found in the dictionary.
    /// The localizedDescription includes the calculated dictionary key that was used.
    /// - Returns: The entity from ``mockData`` that was pre-populated matching the query.  Must be
    /// an entity of the correct type.
    /// > Tip: First create your query and run the code, then look at the `localizedDescription` of the thrown error to
    /// find the key that must be populated in the ``mockData``.
    override open func searchForOne<T: KeychainQuerying>(_ querying: T) throws -> T.Entity {
        let theKey = key(for: querying)

        if let result = mockData[theKey] as? T.Entity {
            return result
        }
        throw NSError(domain: Self.errorDomain, code: 1,
                      userInfo: [NSLocalizedDescriptionKey: "Missing mock data for '\(theKey)'"])
    }

    /// Looks through the ``mockData`` dictionary for an entry matching the query.
    /// - Parameter querying: An instance of a type that conforms to the `KeychainQuerying` protocol.
    /// - Throws: An `NSError` with the ``errorDomain`` domain if no entry is found in the dictionary.
    /// The localizedDescription includes the calculated dictionary key that was used.
    /// - Returns: The entity from ``mockData`` that was pre-populated matching the query.  Must be
    /// an array of the correct entity type.
    /// > Tip: First create your query and run the code, then look at the `localizedDescription` of the thrown error to
    /// find the key that must be populated in the ``mockData``.
    override open func search<T: KeychainQuerying>(_ querying: T) throws -> [T.Entity] {
        let theKey = key(for: querying)

        if let result = mockData[theKey] as? [T.Entity] {
            return result
        }
        throw NSError(domain: Self.errorDomain, code: 2,
                      userInfo: [NSLocalizedDescriptionKey: "Missing mock data for '\(theKey)'"])
    }

    /// Save an item in the ``mockData`` dictionary based on the query.
    /// - Parameters:
    ///   - item: An instance of a `SecurityFrameworkQuery`.
    /// - Throws: An `NSError` with the ``errorDomain`` domain if an entry is already in
    /// the ``mockData`` dictionary and the `updateExisting` parameter is false.
    /// The localizedDescription includes the calculated dictionary key that was used.
    override open func save(_ item: SecurityFrameworkQuery) throws {
        let theKey = key(for: item)

        if mockData[theKey] == nil {
            mockData[theKey] = item
        } else {
            // This must throw this specific error message because the save/update mechanism looks for duplicate items.
            throw HaversackError.keychainError(errSecDuplicateItem)
        }
    }

    /// Looks through the ``mockData`` dictionary for an entry matching the query.
    /// - Parameter query: An instance of a `Haversack/SecurityFrameworkQuery`.
    /// - Returns: Returns the private key of a new cryptographic key pair.
    /// - Throws: An `NSError` object if the key cannot be found. Prior to throwing, also stores the query in the ``mockData`` for future inspection.
    override open func generateKey(_ query: SecurityFrameworkQuery) throws -> SecKey {
        let theKey = key(for: query)

        if let key = mockData[theKey] {
            // swiftlint:disable:next force_cast
            return key as! SecKey
        }

        mockData[theKey] = query
        throw NSError(domain: Self.errorDomain, code: 3,
                      userInfo: [NSLocalizedDescriptionKey: "Missing mock data for '\(theKey)'"])
    }

    /// Remove an item from ``mockData``  based on the query.
    /// - Parameters
    ///   - item: An instance of a `SecurityFrameworkQuery`.
    ///   - treatNotFoundAsSuccess: With this set to true, if the item is not found in the dictionary no
    /// error is thrown.
    /// - Throws: An `NSError` with the ``errorDomain`` domain if no entry is found in the dictionary.
    /// The localizedDescription includes the calculated dictionary key that was used.
    /// > Tip: First create your query and run the code, then look at the `localizedDescription` of the thrown error to
    /// find the key that must be populated in the ``mockData``.
    override open func delete(_ item: SecurityFrameworkQuery, treatNotFoundAsSuccess: Bool) throws {
        let theKey = key(for: item)

        if mockData[theKey] == nil && !treatNotFoundAsSuccess {
            throw NSError(domain: Self.errorDomain, code: 4,
                          userInfo: [NSLocalizedDescriptionKey: "Attempting to delete mock data for '\(theKey)'"])
        }

        mockData.removeValue(forKey: theKey)
    }

    #if os(macOS)
    /// Returns the ``mockImportedEntities`` if their type matches the `EntityType` of the configuration.
    /// - Parameters:
    ///   - items: The items to import, represented as `Data`. This parameter is ignored for this strategy.
    ///   - configuration: The configuration to use when importing items.
    ///   - importKeychain: The keychain to import to (if any).
    /// - Returns: The items in ``mockImportedEntities``
    /// - Throws: Either ``mockImportError`` or an `NSError` with the ``errorDomain`` domain if the
    /// items in ``mockImportedEntities`` don't match the type of the `EntityType` of the `configuration` parameter.
    override open func importItems<EntityType: KeychainImportable>(_ items: Data, configuration: KeychainImportConfig<EntityType>, importKeychain: SecKeychain? = nil) throws -> [EntityType] {
        if let keyImportConfig = configuration as? KeychainImportConfig<KeyEntity> {
            keyImportConfiguration = keyImportConfig
        } else if let certificateImportConfig = configuration as? KeychainImportConfig<CertificateEntity> {
            certificateImportConfiguration = certificateImportConfig
        } else if let identityImportConfig = configuration as? KeychainImportConfig<IdentityEntity> {
            identityImportConfiguration = identityImportConfig
        }

        if let mockImportError {
            throw mockImportError
        }

        guard let mockEntities = mockImportedEntities as? [EntityType] else {
            throw NSError(domain: Self.errorDomain, code: 5,
                          userInfo: [NSLocalizedDescriptionKey: "Tried to return mock entities that weren't all the expected type of '\(EntityType.self)'"])
        }

        return mockEntities
    }

    /// Returns ``mockExportedData`` unless ``mockExportError`` is defined.
    /// - Parameters:
    ///   - items: The keychain entities to export.
    ///   - configuration: The configuration to use when exporting items.
    /// - Returns: The data specified by ``mockExportedData``.
    /// - Throws: ``mockExportError`` if set, otherwise won't throw.
    override open func exportItems(_ items: [any KeychainExportable], configuration: KeychainExportConfig) throws -> Data {
        exportConfiguration = configuration

        if let mockExportError {
            throw mockExportError
        }

        return mockExportedData
    }
    #endif

    // MARK: Calculate dictionary keys
    func key<T: KeychainQuerying>(for querying: T) -> String {
        return key(for: querying.query)
    }

    func key(for query: SecurityFrameworkQuery) -> String {
        let keys = query.keys.sorted()
        let key = keys.reduce("") { (result, key: String) -> String in
            let possible = result + key
            if let valueString = query[key] as? String {
                // Note: We are only taking the first four characters of the string data in order to make shorter keys.
                // Be sure you don't make unit tests that rely on differences at the end of longer strings.
                return possible + valueString.prefix(4)
            } else if let valueInt = query[key] as? Int {
                return possible + String(valueInt)
            }
            return possible
        }

        return key
    }
}
