// SPDX-License-Identifier: MIT
// Copyright 2023, Jamf

import Foundation

/// Represents a connection to a keychain.
///
/// Contains keychain search functionality and the ability to add/update/delete items in the keychain.
public struct Haversack {
    /// The configuration that the Haversack was created with.
    public let configuration: HaversackConfiguration

    /// Create a connection to a keychain
    /// - Parameter configuration: Options on how to connect to the keychain.
    public init(configuration: HaversackConfiguration = HaversackConfiguration()) {
        self.configuration = configuration
    }

    // MARK: - Search

    /// Synchronously search for a single item in the keychain.
    /// - Parameters:
    ///     - query: The fluent keychain query.
    /// - Throws: A ``HaversackError`` if the query returns no items or any errors occur.
    /// - Returns: Something conforming to the ``KeychainStorable`` protocol, based on the query type.
    public func first<T: KeychainQuerying>(where query: T) throws -> T.Entity {
        return try configuration.serialQueue.sync {
            let localQuery = try makeSearchQuery(query, singleItem: true)

            return try self.configuration.strategy.searchForOne(localQuery)
        }
    }

    /// Asynchronously search for a single item in the keychain.
    /// - Parameters:
    ///   - query: The fluent keychain query.
    ///   - completionQueue: The `completion` function will be called on this queue if given, or
    ///   the configuration's strategy's `serialQueue` if this is `nil`.
    ///   - completion: A function/block to be called when the search operation is completed.
    ///   - result: The item or an error will be given to the completion handler.
    public func first<T: KeychainQuerying>(where query: T, completionQueue: OperationQueue? = nil,
                                           completion: @escaping (_ result: Result<T.Entity, Error>) -> Void) {
        configuration.serialQueue.async {
            let result: Result<T.Entity, Error>
            do {
                let localQuery = try makeSearchQuery(query, singleItem: true)

                let entity = try self.configuration.strategy.searchForOne(localQuery)
                result = .success(entity)
            } catch {
                result = .failure(error)
            }

            call(completionHandler: completion, onQueue: completionQueue, with: result)
        }
    }

    /// Synchronously search for multiple items in the keychain.
    /// - Parameters:
    ///     query: The fluent keychain query.
    /// - Throws: A ``HaversackError`` if the query returns no items or any errors occur.
    /// - Returns: An array of items conforming to the ``KeychainStorable`` protocol, based on the query type.
    public func search<T: KeychainQuerying>(where query: T) throws -> [T.Entity] {
        try configuration.serialQueue.sync {
            let localQuery = try makeSearchQuery(query, singleItem: false)

            return try self.configuration.strategy.search(localQuery)
        }
    }

    /// Asynchronously search for multiple items in the keychain.
    /// - Parameters:
    ///   - query: The fluent keychain query.
    ///   - completionQueue: The `completion` function will be called on this queue if given, or
    ///   the configuration's strategy's `serialQueue` if this is `nil`.
    ///   - completion: A function/block to be called when the search operation is completed.
    ///   - result: An array of items or an error will be given to the completion handler.
    public func search<T: KeychainQuerying>(where query: T, completionQueue: OperationQueue? = nil,
                                            completion: @escaping (_ result: Result<[T.Entity], Error>) -> Void) {
        configuration.serialQueue.async {
            let result: Result<[T.Entity], Error>
            do {
                let localQuery = try makeSearchQuery(query, singleItem: true)

                let entities = try self.configuration.strategy.search(localQuery)
                result = .success(entities)
            } catch {
                result = .failure(error)
            }

            call(completionHandler: completion, onQueue: completionQueue, with: result)
        }
    }

    // MARK: - Saving

    /// Synchronously save/update an item in the keychain.
    /// - Parameters:
    ///   - item: The item to save/update.
    ///   - itemSecurity: Specify the security posture of the keychain item
    ///   - updateExisting: If the item already exists in the keychain set this to `true` to update that item.
    ///     Otherwise an ``HaversackError/keychainError(_:)`` with `errSecDuplicateItem` is thrown.
    /// - Throws: A ``HaversackError`` if the query returns no items or any errors occur.
    /// - Returns: The original `item`.
    @discardableResult
    public func save<T: KeychainStorable>(_ item: T, itemSecurity: ItemSecurity, updateExisting: Bool) throws -> T {
        try configuration.serialQueue.sync {
            try unsynchronizedSave(item, itemSecurity: itemSecurity, updateExisting: updateExisting)
        }
    }

    /// Asynchronously save/update an item in the keychain.
    /// - Parameters:
    ///   - item: The item to save/update.
    ///   - itemSecurity: Specify the security posture of the keychain item
    ///   - updateExisting: If the item already exists in the keychain set this to `true` to update that item.
    ///     Otherwise an ``HaversackError/keychainError(_:)`` with `errSecDuplicateItem` is thrown.
    ///   - completionQueue: The `completion` function will be called on this queue if given, or
    ///   the configuration's strategy's `serialQueue` if this is `nil`.
    ///   - completion: A function/block to be called when the save operation is completed.
    ///   - result: The original `item` that was saved or an error will be given to the completion handler.
    public func save<T: KeychainStorable>(_ item: T, itemSecurity: ItemSecurity, updateExisting: Bool,
                                          completionQueue: OperationQueue? = nil,
                                          completion: @escaping (_ result: Result<T, Error>) -> Void) {
        configuration.serialQueue.async {
            let result: Result<T, Error>

            do {
                let theItem = try unsynchronizedSave(item, itemSecurity: itemSecurity, updateExisting: updateExisting)
                result = .success(theItem)
            } catch {
                result = .failure(error)
            }

            call(completionHandler: completion, onQueue: completionQueue, with: result)
        }
    }

    // MARK: - Deletion

    /// Synchronously delete an item from the keychain that was previously retrieved from the keychain.
    ///
    /// If the item does not include a `reference` previously retrieved from the keychain: on iOS/tvOS/visionOS/watchOS
    /// all items matching the item metadata will be deleted, while on macOS only the first matching item will be deleted.
    /// - Parameter item: The item retrieved from the keychain.
    /// - Parameter treatNotFoundAsSuccess: If true, no error is thrown when the query does not
    /// find an item to delete; default is true.
    /// - Throws: A ``HaversackError`` object if any errors occur.
    public func delete<T: KeychainStorable>(_ item: T, treatNotFoundAsSuccess: Bool = true) throws {
        try configuration.serialQueue.sync {
            try self.unsynchronizedDelete(item, treatNotFoundAsSuccess: treatNotFoundAsSuccess)
        }
    }

    /// Aynchronously delete an item from the keychain that was previously retrieved from the keychain.
    ///
    /// If the item does not include a `reference` previously retrieved from the keychain: on iOS/tvOS/visionOS/watchOS
    /// all items matching the item metadata will be deleted, while on macOS only the first matching item will be deleted.
    /// - Parameters:
    ///   - item: The item retrieved from the keychain.
    ///   - treatNotFoundAsSuccess: If true, no error is thrown when the query does not find an
    ///   item to delete; default is true.
    ///   - completionQueue: The `completion` function will be called on this queue if given, or
    ///   the configuration's strategy's `serialQueue` if this is `nil`.
    ///   - completion: A function/block to be called when the delete operation is completed.
    ///   - error: If an error occurs during the delete operation it will be given to the completion
    ///   block; a `nil` represents no error.
    public func delete<T: KeychainStorable>(_ item: T, treatNotFoundAsSuccess: Bool = true,
                                            completionQueue: OperationQueue? = nil,
                                            completion: @escaping (_ error: Error?) -> Void) {
        configuration.serialQueue.async {
            let result: Error?

            do {
                try self.unsynchronizedDelete(item, treatNotFoundAsSuccess: treatNotFoundAsSuccess)
                result = nil
            } catch {
                result = error
            }

            if let actualQueue = completionQueue {
                actualQueue.addOperation {
                    completion(result)
                }
            } else {
                completion(result)
            }
        }
    }

    /// Synchronously delete one or more items from the keychain based on a search query.
    /// - Parameter query: A Haversack query item
    /// - Parameter treatNotFoundAsSuccess: If true, no error is thrown when the query does not
    /// find an item to delete; default is true.
    /// - Throws: A ``HaversackError`` object if any errors occur.
    public func delete<T: KeychainQuerying>(where query: T, treatNotFoundAsSuccess: Bool = true) throws {
        try configuration.serialQueue.sync {
            let localQuery = try makeDeleteQuery(query)
            try self.configuration.strategy.delete(localQuery.query, treatNotFoundAsSuccess: treatNotFoundAsSuccess)
        }
    }

    /// Asynchronously delete one or more items from the keychain based on a search query.
    /// - Parameters:
    ///   - query: A Haversack search query.
    ///   - treatNotFoundAsSuccess: If true, no error is thrown when the query does not find
    ///   an item to delete; default is true.
    ///   - completionQueue: The `completion` function will be called on this queue if given, or
    ///   the configuration's strategy's `serialQueue` if this is `nil`.
    ///   - completion: A function/block to be called when the delete operation is completed.
    ///   - error: If an error occurs during the delete operation it will be given to the completion
    ///   block; a `nil` represents no error.
    public func delete<T: KeychainQuerying>(where query: T, treatNotFoundAsSuccess: Bool = true,
                                            completionQueue: OperationQueue? = nil,
                                            completion: @escaping (_ error: Error?) -> Void) {
        configuration.serialQueue.async {
            let result: Error?

            do {
                let localQuery = try makeDeleteQuery(query)
                try self.configuration.strategy.delete(localQuery.query, treatNotFoundAsSuccess: treatNotFoundAsSuccess)
                result = nil
            } catch {
                result = error
            }

            if let actualQueue = completionQueue {
                actualQueue.addOperation {
                    completion(result)
                }
            } else {
                completion(result)
            }
        }
    }

    // MARK: Importing/Exporting
#if os(macOS)
    /// Export one or more certificates, identities, or keys from the keychain
    /// - Parameters:
    ///   - entities: The entities to export
    ///   - config: A configuration representing all the options that can be provided to `SecItemExport`
    /// - Returns: The exported data
    public func exportItems(_ entities: [any KeychainExportable], config: KeychainExportConfig) throws -> Data {
        try configuration.serialQueue.sync {
            try configuration.strategy.exportItems(entities, configuration: config)
        }
    }

    /// Import one or more certificates, identities, or keys to the keychain
    ///
    /// - Parameters:
    ///   - data: The certificates, identities, or keys represented as `Data`
    ///   - config: A configuration representing all the options that can be provided to `SecItemImport`
    /// - Returns: An array of all the items that were imported
    public func importItems<EntityType: KeychainImportable>(_ data: Data, config: KeychainImportConfig<EntityType>) throws -> [EntityType] {
        try configuration.serialQueue.sync {
            guard
                config.shouldImportIntoKeychain,
                let actualKeychain = configuration.keychain
            else {
                return try configuration.strategy.importItems(data, configuration: config)
            }

            try actualKeychain.attemptToOpen()
            return try configuration.strategy.importItems(data, configuration: config, importKeychain: actualKeychain.reference)
        }
    }
#endif

    // MARK: - Key generation

    /// Create a new asymmetric cryptographic key pair.
    ///
    /// By default the private key will be stored in the keychain, although this behavior can be changed in the `config` parameter.
    /// - Parameters:
    ///   - config: Key metadata properties describing how the key should be generated.
    ///   - itemSecurity: What kind of security to place on the key; note that for Secure Enclave keys, the `config` contains all of the needed information.
    /// - Throws: A ``HaversackError`` if any errors occur.
    /// - Returns: A new `SecKey`
    public func generateKey(fromConfig config: KeyGenerationConfig, itemSecurity: ItemSecurity) throws -> SecKey {
        return try configuration.serialQueue.sync {
            return try unsynchronizedKeyGeneration(fromConfig: config, itemSecurity: itemSecurity)
        }
    }

    /// Asynchronously create a new asymmetric cryptographic key pair.
    ///
    /// By default the private key will be stored in the keychain, although this behavior can be changed in the `config` parameter.
    /// - Parameters:
    ///   - config: Key metadata properties describing how the key should be generated.
    ///   - itemSecurity: What kind of security to place on the key; note that for Secure Enclave keys, the `config` contains all of the needed information.
    ///   - completionQueue: The `completion` function will be called on this queue if given, or
    ///   the configuration's strategy's `serialQueue` if this is `nil`.
    ///   - completion: A function/block to be called when the key has been generated.
    ///   - result: A new `SecKey` or an error.
    public func generateKey(fromConfig config: KeyGenerationConfig, itemSecurity: ItemSecurity,
                            completionQueue: OperationQueue? = nil,
                            completion: @escaping (_ result: Result<SecKey, Error>) -> Void) {
        configuration.serialQueue.async {
            let result: Result<SecKey, Error>

            do {
                let key = try unsynchronizedKeyGeneration(fromConfig: config, itemSecurity: itemSecurity)
                result = .success(key)
            } catch {
                result = .failure(error)
            }

            call(completionHandler: completion, onQueue: completionQueue, with: result)
        }
    }

    // MARK: - Private

    /// Internal function to do additional checks that Haversack's type-safety does not account for.
    /// - Parameter query: A query intended for the Security framework
    /// - Throws: A `HaversackError` if any problems are found
    private func precheck(_ query: SecurityFrameworkQuery) throws {
        #if os(macOS)
        if (query[kSecClass as String] as? String == kSecClassCertificate as String
                || query[kSecClass as String] as? String == kSecClassIdentity as String)
            && query[kSecAttrAccessControl as String] != nil {
            throw HaversackError.notPossible("KeychainItemRetrievability.complex() can't be used with certificates or identities on macOS [kSecAttrAccessControl].")
        }
        #endif
    }

    /// Searches need to be prechecked for issues that Haversack's type-safety does not account for.
    /// - Parameters:
    ///   - query: The fluent keychain query.
    ///   - singleItem: True if the search is supposed to look for a single item; false if the search is for multiple items.
    /// - Returns: A fluent keychain query to use for actual searching.
    private func precheckSearch<T: KeychainQuerying>(_ query: T, singleItem: Bool = false) throws -> T {
        var result: T
        #if os(macOS)
            result = try self.addKeychain(to: query)
        #else
            result = query
        #endif

        // If no other data is being returned, set up to return data
        if result.query[kSecReturnData as String] == nil
            && result.query[kSecReturnAttributes as String] == nil
            && result.query[kSecReturnRef as String] == nil
            && result.query[kSecReturnPersistentRef as String] == nil {
            result = result.returning(.data)
        }

        if singleItem {
            result.query[kSecMatchLimit as String] = kSecMatchLimitOne
        } else {
            if (result.query[kSecClass as String] as? String == kSecClassGenericPassword as String
                || result.query[kSecClass as String] as? String == kSecClassInternetPassword as String)
                && result.query[kSecReturnData as String] as? Bool == true {
                // swiftlint:disable:next line_length
                throw HaversackError.notPossible("Search for multiple password items cannot return password data; use .first(where:) to find one password item or .returning(.persistentRef) or .returning(.reference) to find multiple items without password data")
            }
            result.query[kSecMatchLimit as String] = kSecMatchLimitAll
        }

        return result
    }

    /// Detects whether a given entity query has more than the most basic of information.
    ///
    /// We need to know this because when saving a new item such as a certificate that is already in the keychain
    /// if the query has no other parameters to update there is no need to actually update the keychain info.
    /// Basic info is defined as only the type of keychain item (`kSecClass`) and a reference or persistent reference.
    /// - Parameter query: An entity query
    /// - Returns: True if the query has more than basic info.
    private func moreThanBaseData(in query: SecurityFrameworkQuery) -> Bool {
        // Note: Use a `Set` here for performance.
        let baseKeys: Set<CFString> = [kSecClass, kSecValueRef, kSecValuePersistentRef]
        let queryKeys = query.keys

        // Actually looking for any keys that are NOT in the baseKeys
        return queryKeys.contains { key in
            !baseKeys.contains(key as CFString)
        }
    }

    /// Merge the security keys with the key generation config's keys.  Security key wins any tie.
    /// - Parameters:
    ///   - keyConfig: Info on the key being generated.
    ///   - itemSecurity: The security parameters for the item being stored
    /// - Returns: A SecurityFramework query dictionary
    private func merge(keyConfig: KeyGenerationConfig, withSecurity: ItemSecurity) -> SecurityFrameworkQuery {
        let security = withSecurity.query
        return keyConfig.query.merging(security, uniquingKeysWith: { (_, securityValue) in
            return securityValue
        })
    }

    /// Merge the security keys with the item's keys.  Security key wins any tie.
    /// - Parameters:
    ///   - item: The item being stored
    ///   - itemSecurity: The security parameters for the item being stored
    /// - Returns: A SecurityFramework query dictionary
    private func merge<T: KeychainStorable>(item: T, withSecurity: ItemSecurity) -> SecurityFrameworkQuery {
        let query = item.entityQuery(includeSecureData: true)
        let security = withSecurity.query
        return query.merging(security, uniquingKeysWith: { (_, securityValue) in
            return securityValue
        })
    }

#if os(macOS)
    private func addKeychain<T: KeychainQuerying>(to query: T) throws -> T {
        if let actualKeychain = configuration.keychain {
            try actualKeychain.attemptToOpen()
            return query.in(keychain: actualKeychain.reference)
        }
        return query
    }

    private func addKeychain(to inQuery: SecurityFrameworkQuery, forAdd: Bool) throws -> SecurityFrameworkQuery {
        if let actualKeychain = configuration.keychain {
            try actualKeychain.attemptToOpen()

            var result = inQuery
            if forAdd {
                result[kSecUseKeychain as String] = actualKeychain.reference
            } else {
                result[kSecMatchSearchList as String] = [actualKeychain.reference]
            }
            return result
        }

        return inQuery
    }
#endif

    private func call<T>(completionHandler: @escaping (_ result: Result<T, Error>) -> Void,
                         onQueue queue: OperationQueue?, with result: Result<T, Error>) {
        if let actualQueue = queue {
            actualQueue.addOperation {
                completionHandler(result)
            }
        } else {
            completionHandler(result)
        }
    }

    // MARK: - Unsynchronized

    /// Save the entity and attempt to delete/save if needed on `errSecDuplicateItem` errors.
    private func unsynchronizedSave<T: KeychainStorable>(_ saveQuery: SecurityFrameworkQuery, deleteIfNeeded item: T) throws {
        do {
            try configuration.strategy.save(saveQuery)
        } catch HaversackError.keychainError(let status) {
            if status == errSecDuplicateItem && moreThanBaseData(in: item.entityQuery(includeSecureData: false)) {
                try unsynchronizedDelete(item, treatNotFoundAsSuccess: false)
                try configuration.strategy.save(saveQuery)
            }
        }
    }

    private func unsynchronizedSave<T: KeychainStorable>(_ item: T, itemSecurity: ItemSecurity, updateExisting: Bool) throws -> T {
        let query = try makeSaveQuery(item, itemSecurity: itemSecurity)

        if updateExisting {
            try unsynchronizedSave(query, deleteIfNeeded: item)
        } else {
            try self.configuration.strategy.save(query)
        }

        return item
    }

    private func unsynchronizedKeyGeneration(fromConfig config: KeyGenerationConfig,
                                             itemSecurity: ItemSecurity) throws -> SecKey {
        let query = try makeKeyGenerationQuery(fromConfig: config, itemSecurity: itemSecurity)

        return try self.configuration.strategy.generateKey(query)
    }

    private func unsynchronizedDelete<T: KeychainStorable>(_ item: T, treatNotFoundAsSuccess: Bool) throws {
        let localQuery = try makeDeleteQuery(item)

        try self.configuration.strategy.delete(localQuery, treatNotFoundAsSuccess: treatNotFoundAsSuccess)
    }
}

// MARK: Query builders
extension Haversack {
    package func makeSearchQuery<T: KeychainQuerying>(_ query: T, singleItem: Bool) throws -> T {
        try precheckSearch(query, singleItem: singleItem)
    }

    package func makeSaveQuery<T: KeychainStorable>(_ item: T, itemSecurity: ItemSecurity) throws -> SecurityFrameworkQuery {
        var query = self.merge(item: item, withSecurity: itemSecurity)

#if os(macOS)
        query = try self.addKeychain(to: query, forAdd: true)
#endif

        try self.precheck(query)

        return query
    }

    package func makeDeleteQuery<T: KeychainStorable>(_ item: T) throws -> SecurityFrameworkQuery {
        var result = item.entityQuery(includeSecureData: false)

#if os(macOS)
        result = try self.addKeychain(to: result, forAdd: false)
        // iOS does not support kSecMatchLimit for delete operations
        result[kSecMatchLimit as String] = kSecMatchLimitOne
#endif

        return result
    }

    package func makeDeleteQuery<T: KeychainQuerying>(_ query: T) throws -> T {
        var localQuery: T
#if os(macOS)
        localQuery = try self.addKeychain(to: query)
#else
        localQuery = query
#endif
        return localQuery
    }

    package func makeKeyGenerationQuery(fromConfig config: KeyGenerationConfig, itemSecurity: ItemSecurity) throws -> SecurityFrameworkQuery {
        var query = self.merge(keyConfig: config, withSecurity: itemSecurity)

#if os(macOS)
        query = try self.addKeychain(to: query, forAdd: true)
#endif

        try self.precheck(query)

        return query
    }
}
