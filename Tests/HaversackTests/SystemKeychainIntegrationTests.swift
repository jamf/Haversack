// SPDX-License-Identifier: MIT
// Copyright 2023, Jamf

import XCTest
import Haversack
import HaversackMock

#if os(macOS)

final class SystemKeychainIntegrationTests: XCTestCase {
    var haversack: Haversack!
    var strategy: HaversackEphemeralStrategy!

    override func setUp() {
        strategy = HaversackEphemeralStrategy()
        let config = HaversackConfiguration(strategy: strategy, keychain: .system)
        haversack = Haversack(configuration: config)
    }

    override func tearDown() {
        strategy = nil
        haversack = nil
    }

    func testSearchSystemKeychainMock() throws {
        // given
        let testService = "system.pw"
        let expectedEntity = GenericPasswordEntity()
        expectedEntity.service = testService
        strategy.mockData["classgenpm_Limitm_Lim_SearchListr_Refsvcesyst"] = expectedEntity

        let pwQuery = GenericPasswordQuery(service: testService)
            .returning(.reference)

        // when
        let actual = try haversack.first(where: pwQuery)

        // then
        XCTAssertNotNil(actual)
        XCTAssertEqual(actual.service, testService)
    }

    func testSaveToSystemKeychainMock() throws {
        // given
        let aPassword = GenericPasswordEntity()
        aPassword.service = "A password"
        aPassword.passwordData = "super secret".data(using: .utf8)

        // when
        let actual = try haversack.save(aPassword, itemSecurity: .standard, updateExisting: false)

        // then
        XCTAssertNotNil(actual)
        let insertedData = try XCTUnwrap(strategy.mockData["classgenppdmnakusvceA pau_Keychainv_Data"] as? SecurityFrameworkQuery)
        XCTAssertEqual(insertedData[kSecClass as String] as? String, kSecClassGenericPassword as String)
        XCTAssertEqual(insertedData[kSecAttrService as String] as? String, aPassword.service)
        XCTAssertEqual(insertedData[kSecValueData as String] as? Data, aPassword.passwordData)
        XCTAssertNotNil(insertedData[kSecAttrAccessible as String] as? String, kSecAttrAccessibleWhenUnlockedThisDeviceOnly as String)
        XCTAssertNotNil(insertedData[kSecUseKeychain as String])
    }

    func testDeleteFromSystemKeychainMock() throws {
        // given
        strategy.mockData["classgenpm_SearchListsvceMySe"] = "something to delete"
        let pwQuery = GenericPasswordQuery(service: "MyService")

        // when
        try haversack.delete(where: pwQuery)

        // then
        XCTAssertTrue(strategy.mockData.isEmpty)
    }
}

#endif
