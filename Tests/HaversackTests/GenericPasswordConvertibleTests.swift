// SPDX-License-Identifier: MIT
// Copyright 2023, Jamf

import XCTest
import Haversack
import HaversackMock

/// A type that conforms to ``GenericPasswordConvertible`` that uses JSON to encode/decode into `Data`.
struct MyTestType: Codable, GenericPasswordConvertible {
    let aString: String
    let anInt: Int

    static func make(fromRaw data: Data) throws -> Self {
        return try JSONDecoder().decode(Self.self, from: data)
    }

    var rawRepresentation: Data {
        (try? JSONEncoder().encode(self)) ?? Data()
    }
}

/// A type that conforms to ``GenericPasswordConvertible`` whose `Data` representation is simply the string "Hello"
struct SecondTestType: GenericPasswordConvertible {
    static func make(fromRaw data: Data) throws -> Self {
        if let asString = String(data: data, encoding: .utf8) {
            if asString == "Hello" {
                return Self()
            }
        }
        throw NSError(domain: "haversacktests", code: 1, userInfo: nil)
    }

    var rawRepresentation = "Hello".data(using: .utf8)!
}

final class GenericPasswordConvertibleTests: XCTestCase {
    var haversack: Haversack!
    var strategy: HaversackEphemeralStrategy!

    override func setUp() {
        strategy = HaversackEphemeralStrategy()
        let config = HaversackConfiguration(strategy: strategy)
        haversack = Haversack(configuration: config)
    }

    override func tearDown() {
        strategy = nil
        haversack = nil
    }

    func testMyTestTypeCanSave() throws {
        // given
        let testInstance = MyTestType(aString: "unit test", anInt: 7)

        // when
        let entity = GenericPasswordEntity(testInstance)
        entity.service = "testing"
        let actual = try haversack.save(entity, itemSecurity: .standard, updateExisting: false)

        // then
        XCTAssertIdentical(actual, entity)
        let insertedData = try XCTUnwrap(strategy.mockData["classgenppdmnakusvcetestv_Data"] as? SecurityFrameworkQuery)
        XCTAssertEqual(insertedData.count, 4)
        XCTAssertEqual(insertedData[kSecClass as String] as? String, kSecClassGenericPassword as String)
        XCTAssertEqual(insertedData[kSecAttrService as String] as? String, "testing")
        XCTAssertEqual(insertedData[kSecAttrAccessible as String] as? String, kSecAttrAccessibleWhenUnlockedThisDeviceOnly as String)
    }

    func testMyTestTypeCanLoad() throws {
        // given
        let expectedEntity = GenericPasswordEntity()
        expectedEntity.service = "test_load"
        expectedEntity.passwordData = #"{"aString":"yes we can","anInt":65}"#.data(using: .utf8)
        strategy.mockData["classgenpm_Limitm_Lir_Datasvcetest"] = expectedEntity

        let query = GenericPasswordQuery(service: "test_load")
        let actual = try haversack.first(where: query)
        XCTAssertEqual(actual.service, "test_load")

        // when
        let mine: MyTestType = try actual.originalEntity()

        // then
        XCTAssertEqual(mine.aString, "yes we can")
        XCTAssertEqual(mine.anInt, 65)
    }

    func testSecondTypeCanLoad() throws {
        // given
        let expectedEntity = GenericPasswordEntity()
        expectedEntity.service = "test_load_2"
        expectedEntity.passwordData = "Hello".data(using: .utf8)
        strategy.mockData["classgenpm_Limitm_Lir_Datasvcetest"] = expectedEntity

        let query = GenericPasswordQuery(service: "test_load")
        let actual = try haversack.first(where: query)
        XCTAssertEqual(actual.service, "test_load_2")

        // when
        _ = try actual.originalEntity() as SecondTestType

        // then - no error was thrown
    }

    func testAttemptedLoadOfWrongTypeThrows() throws {
        // given
        let expectedEntity = GenericPasswordEntity()
        expectedEntity.service = "test_load"
        expectedEntity.passwordData = #"{"aString":"yes we can","anInt":65}"#.data(using: .utf8)
        strategy.mockData["classgenpm_Limitm_Lir_Datasvcetest"] = expectedEntity

        let query = GenericPasswordQuery(service: "test_load")

        // when
        let actual = try haversack.first(where: query)

        // then
        XCTAssertEqual(actual.service, "test_load")
        XCTAssertThrowsError(try actual.originalEntity() as SecondTestType,
                             "The saved data is not a SecondTestType so it should throw an error")
    }
}
