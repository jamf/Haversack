// SPDX-License-Identifier: MIT
// Copyright 2023, Jamf

import XCTest
import Haversack
import HaversackMock

final class EphemeralStrategyTests: XCTestCase {
    var ephemeralStrategy: HaversackEphemeralStrategy!
    var haversack: Haversack!

    override func setUp() {
        ephemeralStrategy = HaversackEphemeralStrategy()
        haversack = Haversack(configuration: .init(strategy: ephemeralStrategy))
    }

    func testInternetPWSearchReferenceMock() throws {
        // Given
        let pwQuery = InternetPasswordQuery(server: "stash")
            .matching(account: "luke")
            .returning(.reference)

        let expectedEntity = InternetPasswordEntity()
        expectedEntity.protocol = .appleTalk
        try haversack.setSearchFirstMock(where: pwQuery, mockValue: expectedEntity)

        // When
        let password = try haversack.first(where: pwQuery)

        // Then
        XCTAssertNotNil(password)
        XCTAssertEqual(password.protocol, .appleTalk)
    }

    func testGenericPWSearchReferenceMock() throws {
        // given
        let testService = "unit.test"

        let pwQuery = GenericPasswordQuery(service: testService)
            .returning(.reference)

        let expectedEntity = GenericPasswordEntity()
        expectedEntity.service = testService
        try haversack.setSearchFirstMock(where: pwQuery, mockValue: expectedEntity)

        // when
        let password = try haversack.first(where: pwQuery)

        // then
        XCTAssertNotNil(password)
        XCTAssertEqual(password.service, testService)
    }

    #if os(macOS)
    func testImportItemsIncorrectMockEntities() throws {
        // Given
        ephemeralStrategy.mockImportedEntities = [ KeyEntity() ]

        let importConfig = KeychainImportConfig<CertificateEntity>()

        // When
        XCTAssertThrowsError(try haversack.importItems(Data(), config: importConfig))

        // Then
        XCTAssertNotNil(ephemeralStrategy.certificateImportConfiguration)
    }
    #endif

    // MARK: Mocking tests

    func testSetSearchFirstMock() throws {
        // Given
        let testService = "unit.test"
        let pwQuery = GenericPasswordQuery(service: testService)
            .returning(.reference)

        let expectedEntity = GenericPasswordEntity()
        expectedEntity.service = testService
        try haversack.setSearchFirstMock(where: pwQuery, mockValue: expectedEntity)

        // When
        let password = try haversack.first(where: pwQuery)

        // Then no error should be thrown

        // And the returned value should match the data that was set
        XCTAssertNotNil(password)
        XCTAssertEqual(password.service, testService)
    }

    func testSetSearchMock() throws {
        // Given
        let testService = "unit.test"
        let pwQuery = GenericPasswordQuery(service: testService)
            .returning(.reference)

        let expectedEntity = GenericPasswordEntity()
        expectedEntity.service = testService
        try haversack.setSearchMock(where: pwQuery, mockValue: [expectedEntity])

        // When
        let passwords = try haversack.search(where: pwQuery)

        // Then no error should be thrown

        // And the returned value should match the data that was set
        let password = try XCTUnwrap(passwords.first)
        XCTAssertEqual(password.service, testService)
    }

    func testSetSaveMock() throws {
        // Given
        let mockEntity = GenericPasswordEntity()
        let testService = "unit.test"
        mockEntity.service = testService

        try haversack.setSaveMock(item: mockEntity, itemSecurity: .standard, mockValue: mockEntity)

        do {
            // When
            try haversack.save(mockEntity, itemSecurity: .standard, updateExisting: false)
        } catch let error as HaversackError {
            // Then attempting to save a value with updateExisting=false should throw
            XCTAssertEqual(error, HaversackError.keychainError(errSecDuplicateItem))
        }
    }

    func testSetDeleteWhereMock() throws {
        // Given
        let pwQuery = GenericPasswordQuery()
            .returning(.reference)

        try haversack.setDeleteMock(where: pwQuery, mockValue: "Any value")

        // When
        try haversack.delete(where: pwQuery, treatNotFoundAsSuccess: false)

        // Then no error should be thrown

        // And the value should have been deleted
        XCTAssertNil(try haversack.getDeleteMock(where: pwQuery))
    }

    func testSetDeleteItemMock() throws {
        // Given
        let entity = GenericPasswordEntity()
        try haversack.setDeleteMock(item: entity, mockValue: "Any value")

        // When
        try haversack.delete(entity, treatNotFoundAsSuccess: false)

        // Then no error should be thrown

        // And the value should have been deleted
        XCTAssertNil(try haversack.getDeleteMock(item: entity))
    }

    #if os(macOS)
    func testSetGenerateKeyMock() throws {
        func loadKey() throws -> SecKey {
            let data = try Data(contentsOf: getURLForTestResource(named: "key.bsafe"))
            let config = try KeychainImportConfig<KeyEntity>()
                .inputFormat(.formatBSAFE)
                .returnEntitiesWithoutSaving()

            let importedEntities = try Haversack().importItems(data, config: config)
            return try XCTUnwrap(importedEntities.first?.reference)
        }

        // Given
        let testKey = try loadKey()
        let keyGenerationConfig = KeyGenerationConfig(algorithm: .RSA, keySize: 2048)
        try haversack.setGenerateKeyMock(config: keyGenerationConfig, mockValue: testKey)

        // When
        let key = try haversack.generateKey(fromConfig: keyGenerationConfig, itemSecurity: .standard)

        // Then no error should be thrown

        // And the value in `mockData` should be unchanged
        let mockDataValue = try haversack.getGenerateKeyMock(config: keyGenerationConfig)
        XCTAssertEqual(mockDataValue, key)
    }
    #endif
}
