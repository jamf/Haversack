// SPDX-License-Identifier: MIT
// Copyright 2023, Jamf

import Haversack
import Security
import XCTest

extension Haversack {
    /// A convenience accessor that handles typecasting the `HaversackStrategy` to a `HaversackEphemeralStrategy`
    /// via XCTest's `XCTUnwrap` function.
    var ephemeralStrategy: HaversackEphemeralStrategy {
        get throws {
            try XCTUnwrap(configuration.strategy as? HaversackEphemeralStrategy)
        }
    }
}

// MARK: Mock data setters
extension Haversack {
    /// Mocks data for calls to `Haversack.first(where:)`
    /// - Parameters:
    ///   - query: The query to set a mock value for
    ///   - mockValue: The mock value to set
    public func setSearchFirstMock<T: KeychainQuerying>(where query: T, mockValue: T.Entity) throws {
        let query = try makeSearchQuery(query, singleItem: true)
        try ephemeralStrategy.setMock(mockValue, forQuery: query.query)
    }

    /// Retrieves the value for a call to `Haversack.first(where:)` from ``HaversackEphemeralStrategy/mockData``
    /// - Parameter query: The query to retrieve a value for
    /// - Returns: The value associated with `query` in ``HaversackEphemeralStrategy/mockData``
    public func getSearchFirstMock<T: KeychainQuerying>(where query: T) throws -> T.Entity? {
        let query = try makeSearchQuery(query, singleItem: true)
        return try ephemeralStrategy.getMockDataValue(for: query.query)
    }

    /// Mocks data for calls to `Haversack.search(where:)`
    /// - Parameters:
    ///   - query: The query to set a mock value for
    ///   - mockValue: The mock value to set
    public func setSearchMock<T: KeychainQuerying>(where query: T, mockValue: [T.Entity]) throws {
        let query = try makeSearchQuery(query, singleItem: false)
        try ephemeralStrategy.setMock(mockValue, forQuery: query.query)
    }

    /// Retrieves the value for a call to `Haversack.search(where:)` from ``HaversackEphemeralStrategy/mockData``
    /// - Parameter query: The query to retrieve a value for
    /// - Returns: The value associated with `query` in ``HaversackEphemeralStrategy/mockData``
    public func getSearchMock<T: KeychainQuerying>(where query: T) throws -> [T.Entity]? {
        let query = try makeSearchQuery(query, singleItem: false)
        return try ephemeralStrategy.getMockDataValue(for: query.query)
    }

    /// Mocks data for calls to `Haversack.save(_:itemSecurity:updateExisting:)`. This is useful when
    /// you want to test the behavior of your code when the item being saved already exists in the keychain.
    /// - Parameters:
    ///   - item: The item being saved
    ///   - itemSecurity: The security the item should have
    ///   - mockValue: The mock value to set
    public func setSaveMock<T: KeychainStorable>(item: T, itemSecurity: ItemSecurity = .standard, mockValue: Any) throws {
        let query = try makeSaveQuery(item, itemSecurity: itemSecurity)
        try ephemeralStrategy.setMock(mockValue, forQuery: query)
    }

    /// Retrieves the value for a call to `Haversack.save(_:itemSecurity:updateExisting:)` from ``HaversackEphemeralStrategy/mockData``
    /// - Parameters:
    ///   - item: The item being saved
    ///   - itemSecurity: The security the item should have
    /// - Returns: The value associated with `query` in ``HaversackEphemeralStrategy/mockData``
    public func getSaveMock<T: KeychainStorable>(item: T, itemSecurity: ItemSecurity = .standard) throws -> Any? {
        let query = try makeSaveQuery(item, itemSecurity: itemSecurity)
        return try ephemeralStrategy.getMockDataValue(for: query)
    }

    /// Mocks data for calls to `Haversack.delete(_:treatNotFoundAsSuccess:)`
    /// - Parameters:
    ///   - item: The item to generate a delete query and set a mock value for
    ///   - mockValue: The mock value to set
    public func setDeleteMock<T: KeychainStorable>(item: T, mockValue: Any) throws {
        let query = try makeDeleteQuery(item)
        try ephemeralStrategy.setMock(mockValue, forQuery: query)
    }

    /// Retrieves the value for a call to `Haversack.delete(_:treatNotFoundAsSuccess:)` from ``HaversackEphemeralStrategy/mockData``
    /// - Parameter item: The item to generate a delete query and set a mock value for
    /// - Returns: The value associated with `query` in ``HaversackEphemeralStrategy/mockData``
    public func getDeleteMock<T: KeychainStorable>(item: T) throws -> Any? {
        let query = try makeDeleteQuery(item)
        return try ephemeralStrategy.getMockDataValue(for: query)
    }

    /// Mocks data for calls to `Haversack.delete(where:treatNotFoundAsSuccess:)`
    /// - Parameters:
    ///   - query: The query to set a mock value for
    ///   - mockValue: The mock value to set
    public func setDeleteMock<T: KeychainQuerying>(where query: T, mockValue: Any) throws {
        let query = try makeDeleteQuery(query)
        try ephemeralStrategy.setMock(mockValue, forQuery: query.query)
    }

    /// Retrieves the value for a call to `Haversack.delete(where:treatNotFoundAsSuccess:)` from ``HaversackEphemeralStrategy/mockData``
    /// - Parameter query: The query to retrieve a value for
    /// - Returns: The value associated with `query` in ``HaversackEphemeralStrategy/mockData``
    public func getDeleteMock<T: KeychainQuerying>(where query: T) throws -> Any? {
        let query = try makeDeleteQuery(query)
        return try ephemeralStrategy.getMockDataValue(for: query.query)
    }

    /// Mocks data for calls to `Haversack.generateKey(fromConfig:itemSecurity:)`
    /// - Parameters:
    ///   - config: The key generation configuration values that the query should include
    ///   - itemSecurity: The item security the query should specify
    ///   - mockValue: The mock value to set
    public func setGenerateKeyMock(config: KeyGenerationConfig, itemSecurity: ItemSecurity = .standard, mockValue: SecKey) throws {
        let query = try makeKeyGenerationQuery(fromConfig: config, itemSecurity: itemSecurity)
        try ephemeralStrategy.setMock(mockValue, forQuery: query)
    }

    /// Retrieves the value for a call to `Haversack.generateKey(fromConfig:itemSecurity:)` from ``HaversackEphemeralStrategy/mockData``
    /// - Parameters:
    ///   - config: The key generation configuration values that the query should include
    ///   - itemSecurity: The item security the query should specify
    /// - Returns: The value associated with `query` in ``HaversackEphemeralStrategy/mockData``
    public func getGenerateKeyMock(config: KeyGenerationConfig, itemSecurity: ItemSecurity = .standard) throws -> SecKey? {
        let query = try makeKeyGenerationQuery(fromConfig: config, itemSecurity: itemSecurity)
        return try ephemeralStrategy.getMockDataValue(for: query)
    }
}

extension HaversackEphemeralStrategy {
    /// Generates a ``mockData`` key for the query and sets the value of that key to `mockValue`
    /// - Parameters:
    ///   - mockValue: The value to mock
    ///   - query: The query that the mock value is associated with
    func setMock(_ mockValue: Any, forQuery query: SecurityFrameworkQuery) {
        mockData[key(for: query)] = mockValue
    }

    /// Retrieves the ``mockData`` value for the provided query
    ///
    /// This overload is required because `Optional<Any>` can be typecast to `Any`.
    /// This means that if the generic version of this function were called where `T == Any`,
    /// it would always return a non-nil value of `Any` with the actual type of `Optional<Any>.none`.
    /// - Parameter query: The query to retreive a value for
    /// - Returns: The value
    func getMockDataValue(for query: SecurityFrameworkQuery) -> Any? {
        mockData[key(for: query)]
    }

    /// Retrieves and typecasts the ``mockData`` value for the provided query
    /// - Parameter query: The query to retreive a value for
    /// - Returns: The typecasted value
    func getMockDataValue<T>(for query: SecurityFrameworkQuery) -> T? {
        getMockDataValue(for: query) as? T
    }
}
