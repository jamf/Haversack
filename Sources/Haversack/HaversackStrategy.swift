// SPDX-License-Identifier: MIT
// Copyright 2023, Jamf

import Foundation
import os.log
import Security

/// Encapsulates the explicit code to work with the keychain through the Security framework.
///
/// Subclasses can override any of the functions in order to perform tasks in their own way.
/// The `HaversackMock` module adds a subclass (`HaversackMock/HaversackEphemeralStrategy`)
/// that uses a simple RAM-based dictionary (that can be pre-populated if desired) instead of interacting
/// with the real keychain.
///
/// #### Logging
/// Uses system logging with a subsystem of `com.jamf.haversack`.
/// All item searches are logged at the `.info` level.  Saving and deleting items are logged at
/// the `.default` level.  All errors are logged at the `.error` level with additional query details logged at
/// the `.debug` level and marked as private.
open class HaversackStrategy {
    /// Create a new strategy object
    public init() { }

    /// Search for a single item in the keychain.
    /// - Parameter querying: An instance of a type that conforms to the `KeychainQuerying` protocol.
    /// - Throws: A ``HaversackError`` object if any errors occur (including an "item not found" error).
    /// - Returns: An entity filled in from the keychain with the requested data.
    open func searchForOne<T: KeychainQuerying>(_ querying: T) throws -> T.Entity {
        let query = querying.query
        var result: CFTypeRef?

        if let itemClass = query[kSecClass as String] as? String {
            os_log("Searching for an item of class %{public}@", log: Logs.search, type: .info, itemClass)
        }

        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess && result != nil {
            // What did the query ask for?
            let contents = QueryContents(query: query)

            if let entity = querying.processSingleItem(item: result, hasRef: contents.hasRef, hasData: contents.hasData,
                                                       hasPersistentRef: contents.hasPersistentRef, hasAttrs: contents.hasAttrs) {
                return entity
            }

            os_log("Problem converting item to entity %{public}@", log: Logs.search,
                type: .error, String(describing: T.Entity.self))
            os_log("Problem query was %{private}@", log: Logs.search, type: .debug, String(describing: query))
            throw HaversackError.couldNotConvertToEntity
        }

        os_log("SecItemCopyMatching returned error %{public}d and item was %s", log: Logs.search,
               type: .error, status, (result == nil ? "nil" : "non-nil"))
        os_log("SecItemCopyMatching query was %{private}@", log: Logs.search,
               type: .debug, String(describing: query))
        throw HaversackError.keychainError(status)
    }

    /// Search for potentially many items in the keychain
    /// - Parameter querying: An instance of a type that conforms to the `KeychainQuerying` protocol.
    /// - Throws: A ``HaversackError`` object if any errors occur (including an "item not found" error).
    /// - Returns: An array of entities filled in from the keychain with the requested data.
    open func search<T: KeychainQuerying>(_ querying: T) throws -> [T.Entity] {
        let query = querying.query
        var result: CFTypeRef?

        if let itemClass = query[kSecClass as String] as? String {
            os_log("Searching for items of class %{public}@", log: Logs.search, type: .info, itemClass)
        }

        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess {
            // What did the query ask for?
            let contents = QueryContents(query: query)

            if CFArrayGetTypeID() == CFGetTypeID(result) {
                if contents.shouldBeDictionary, let array = (result as? NSArray) as? [NSDictionary] {
                    return array.compactMap {
                        if let entity = querying.processSingleItem(item: $0, hasRef: contents.hasRef, hasData: contents.hasData,
                                                                   hasPersistentRef: contents.hasPersistentRef,
                                                                   hasAttrs: contents.hasAttrs) {
                            return entity
                        }

                        return nil
                    }
                } else if contents.hasRef, let array = (result as? NSArray) as? [T.Entity.SecurityFrameworkType] {
                    return array.compactMap {
                        return T.Entity(from: $0, data: nil, attributes: nil, persistentRef: nil)
                    }
                } else if contents.hasData, let array = (result as? NSArray) as? [Data] {
                    return array.compactMap {
                        return T.Entity(from: nil, data: $0, attributes: nil, persistentRef: nil)
                    }
                } else if contents.hasPersistentRef, let array = (result as? NSArray) as? [Data] {
                    return array.compactMap {
                        return T.Entity(from: nil, data: nil, attributes: nil, persistentRef: $0)
                    }
                }
                // NOTE: missing the hasAttrs case because that is treated in the `expectDict` case above.

                // Could not convert the returned items to an entity array.
                os_log("Problem converting item to entity %{public}@", log: Logs.search,
                    type: .error, String(describing: T.Entity.self))
                os_log("Problem query was %{private}@", log: Logs.search, type: .debug, String(describing: query))
                throw HaversackError.couldNotConvertToEntity
            } else {
                if let entity = querying.processSingleItem(item: result, hasRef: contents.hasRef, hasData: contents.hasData,
                                                           hasPersistentRef: contents.hasPersistentRef,
                                                           hasAttrs: contents.hasAttrs) {
                    return [entity]
                }

                // Could not convert the single returned item to an entity.
                os_log("Problem converting item to entity %{public}@", log: Logs.search,
                    type: .error, String(describing: T.Entity.self))
                os_log("Problem query was %{private}@", log: Logs.search, type: .debug, String(describing: query))
                throw HaversackError.couldNotConvertToEntity
            }
        }

        os_log("SecItemCopyMatching returned error %{public}d", log: Logs.search, type: .error, status)
        os_log("SecItemCopyMatching query was %{private}@", log: Logs.search, type: .debug, String(describing: query))
        throw HaversackError.keychainError(status)
    }

    /// Save an item in the keychain based on the query.
    /// - Parameters:
    ///   - item: An instance of a `SecurityFrameworkQuery`.
    /// - Throws: A ``HaversackError`` object if any errors occur.
    open func save(_ item: SecurityFrameworkQuery) throws {
        let query = item as CFDictionary

        if let itemClass = item[kSecClass as String] as? String {
            os_log("Saving an item of class %{public}@", log: Logs.save, type: .default, itemClass)
        }

        let status = SecItemAdd(query, nil)
        if status != errSecSuccess {
            os_log("SecItemAdd returned error %{public}d", log: Logs.save, type: .error, status)
            os_log("SecItemAdd query was %{private}@", log: Logs.save, type: .debug, String(describing: query))
            throw HaversackError.keychainError(status)
        }
    }

    /// Delete items in the keychain based on the query.
    /// - Parameters
    ///   - item: An instance of a ``SecurityFrameworkQuery``.
    ///   - treatNotFoundAsSuccess: With this set to true, if the item is not found in the keychain no error is thrown.
    /// - Throws: A ``HaversackError`` object if any errors occur (including an "item not found" error).
    open func delete(_ item: SecurityFrameworkQuery, treatNotFoundAsSuccess: Bool) throws {
        if let itemClass = item[kSecClass as String] as? String {
            os_log("Deleting an item of class %{public}@", log: Logs.delete, type: .default, itemClass)
        }

        // Ensure that we are not trying to delete with a query that contains data.
        var query = item
        query.removeValue(forKey: kSecValueData as String)

        #if !os(macOS)
            // iOS/tvOS/iPadOS do not support delete operations with a limit.
            query.removeValue(forKey: kSecMatchLimit as String)
        #endif

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess
            || (status == errSecItemNotFound && treatNotFoundAsSuccess) else {
            os_log("SecItemDelete returned error %{public}d", log: Logs.delete, type: .error, status)
            os_log("SecItemDelete query was %{private}@", log: Logs.delete, type: .debug, String(describing: item))
            throw HaversackError.keychainError(status)
        }
    }

    /// Create a `SecKey` from the given parameters dictionary.
    ///
    /// This should not be called directly, but is used by ``Haversack/Haversack/generateKey(fromConfig:itemSecurity:)-1r4ki``
    /// to perform the actual key generation.
    /// - Note  The returned key is not stored in the keychain by this call.  Create a ``KeyEntity`` from the key, then call
    /// ``Haversack/Haversack/save(_:itemSecurity:updateExisting:)-5zo28`` (or it's async variant)s with that entity.
    /// - Parameter query: An instance of a ``SecurityFrameworkQuery``.
    /// - Returns: Returns the private key of a new cryptographic key pair.
    /// - Throws: An `NSError` object if any errors occur.
    open func generateKey(_ query: SecurityFrameworkQuery) throws -> SecKey {
        var error: Unmanaged<CFError>?

        let keyType = query[kSecAttrKeyType as String] as? String
        os_log("Generating a key of type %{public}@", log: Logs.keyGeneration, type: .default, keyType ?? "")

        guard let privateKey = SecKeyCreateRandomKey(query as CFDictionary, &error) else {
            let theError = error!.takeRetainedValue() as Error
            os_log("SecKeyCreateRandomKey query was %{private}@", log: Logs.keyGeneration, type: .debug, String(describing: query))
            os_log("SecKeyCreateRandomKey returned error %{public}s", log: Logs.keyGeneration,
                   type: .error, theError.localizedDescription)
            throw theError
        }

        return privateKey
    }

    #if os(macOS)
    /// Exports one or more keys, certificates, or identities from the keychain
    ///
    /// This should not be called directly but is used by ``Haversack/Haversack/exportItems(_:config:)`` to perform the actual exporting
    /// - Parameters:
    ///   - item: The keys, certificates, or identities to export
    ///   - configuration: A configuration representing all the options that can be provided to `SecItemExport`
    /// - Returns: A `Data` representation of the keychain item
    open func exportItems(_ items: [any KeychainExportable], configuration: KeychainExportConfig) throws -> Data {
        let secItems = try items.map { item in
            guard let ref = item.reference else {
                throw HaversackError.notPossible("Exporting a keychain item requires the reference to the item; try using the result of running a Haversack query with .returning(.reference).")
            }

            return ref
        }

        var data: CFData?
        var params = configuration.keyParameters
        let status = SecItemExport(secItems as CFArray, configuration.outputFormat, configuration.flags, &params, &data)

        guard status == errSecSuccess else {
            throw HaversackError.keychainError(status)
        }

        guard let data = data else {
            /// The export succeeded but we didn't receive any data
            throw HaversackError.unknownError
        }

        return data as Data
    }

    /// Imports one or more keys, certificates, or identities and adds them to the keychain
    /// - Parameters:
    ///   - item: The keys, certificates, or identities to import
    ///   - configuration: A configuration representing all the options that can be provided to `SecItemImport`
    /// - Returns: An array of all the keychain items imported
    open func importItems<EntityType: KeychainImportable>(_ items: Data, configuration: KeychainImportConfig<EntityType>, importKeychain: SecKeychain? = nil) throws -> [EntityType] {
        var inputFormat = configuration.inputFormat
        var itemType = configuration.itemType
        var keyParams = configuration.keyParams

        var outItems: CFArray?
        let status = SecItemImport(items as CFData,
                                   configuration.fileNameOrExtension,
                                   &inputFormat,
                                   &itemType,
                                   configuration.secItemImportFlags,
                                   &keyParams,
                                   importKeychain,
                                   &outItems)

        guard status == errSecSuccess else {
            throw HaversackError.keychainError(status)
        }

        guard let outItems = outItems else {
            // The import was a success but there weren't any items returned
            return []
        }

        let cfItems = outItems as [CFTypeRef]
        return cfItems.map { secKeychainItem in
            EntityType(from: secKeychainItem as? EntityType.SecurityFrameworkType,
                       data: nil,
                       attributes: nil,
                       persistentRef: nil)
        }
    }
    #endif
}

/// A simple type that looks into a keychain query to see what kind of data it is asking for.
private struct QueryContents {
    let hasRef: Bool
    let hasData: Bool
    let hasPersistentRef: Bool
    let hasAttrs: Bool
    /// Whether or not `SecItemCopyMatching` should return a dictionary or simple data.
    let shouldBeDictionary: Bool

    init(query: SecurityFrameworkQuery) {
        hasRef = (query[kSecReturnRef as String] as? Bool == true)
        hasData = (query[kSecReturnData as String] as? Bool == true)
        hasPersistentRef = (query[kSecReturnPersistentRef as String] as? Bool == true)
        hasAttrs = (query[kSecReturnAttributes as String] as? Bool == true)

        let hasMoreThanOne = QueryContents.moreThanOne(hasRef, hasData, hasPersistentRef)
        shouldBeDictionary = hasAttrs || hasMoreThanOne
    }

    /// Returns true if two or all three of the given parameters are true.
    /// - Parameters:
    ///   - bool1: First boolean
    ///   - bool2: Second boolean
    ///   - bool3: Third boolean
    /// - Returns: True if at least two of the given parameters are true.
    private static func moreThanOne(_ bool1: Bool, _ bool2: Bool, _ bool3: Bool) -> Bool {
        // If bool1 and bool2 agree, they have the majority vote, so go with whatever it is.
        // Otherwise 1 & 2 disagree so bool3 is the deciding vote.
        return (bool1 == bool2) ? bool1 : bool3
    }
}
