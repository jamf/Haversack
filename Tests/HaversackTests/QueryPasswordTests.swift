// SPDX-License-Identifier: MIT
// Copyright 2023, Jamf

import XCTest
import Haversack

final class QueryPasswordTests: XCTestCase {
    func testGenericPWQueryNoService() throws {
        // given
        let testData = try XCTUnwrap("More data".data(using: .utf8))

        // when
        let keyQuery = GenericPasswordQuery()
            .matching(customData: testData)

        // then
        let actual = keyQuery.query
        XCTAssertEqual(actual.count, 2)
        XCTAssertEqual(actual[kSecClass as String] as! CFString, kSecClassGenericPassword)
        XCTAssertEqual(actual[kSecAttrGeneric as String] as! Data, testData)
    }

    func testGenericPWQueryLabel() {
        // given/when
        let pwQuery = GenericPasswordQuery()
            .matching(label: "A test label")

        // then
        let actual = pwQuery.query
        XCTAssertEqual(actual.count, 2)
        XCTAssertEqual(actual[kSecClass as String] as! CFString, kSecClassGenericPassword)
        XCTAssertEqual(actual[kSecAttrLabel as String] as! String, "A test label")
    }

    func testGenericPWQuery() {
        // given/when
        let pwQuery = GenericPasswordQuery(service: "Jamf Pro server")
            .matching(account: "Self Service - no user")
            .matching(group: 42)

        // then
        let actual = pwQuery.query
        XCTAssertEqual(actual.count, 4)
        XCTAssertEqual(actual[kSecClass as String] as! CFString, kSecClassGenericPassword)
        XCTAssertEqual(actual[kSecAttrService as String] as! String, "Jamf Pro server")
        XCTAssertEqual(actual[kSecAttrAccount as String] as! String, "Self Service - no user")
        XCTAssertEqual(actual[kSecAttrType as String] as! Int, 42)
    }

    func testInternetPWQueryNoServer() {
        // given/when
        let pwQuery = InternetPasswordQuery()
            .matching(account: "Self Service - no user")

        // then
        let actual = pwQuery.query
        XCTAssertEqual(actual.count, 2)
        XCTAssertEqual(actual[kSecClass as String] as! CFString, kSecClassInternetPassword)
        XCTAssertEqual(actual[kSecAttrAccount as String] as! String, "Self Service - no user")
    }

    func testInternetPWQueryLabel() {
        // given/when
        let pwQuery = InternetPasswordQuery()
            .matching(label: "A test label")

        // then
        let actual = pwQuery.query
        XCTAssertEqual(actual.count, 2)
        XCTAssertEqual(actual[kSecClass as String] as! CFString, kSecClassInternetPassword)
        XCTAssertEqual(actual[kSecAttrLabel as String] as! String, "A test label")
    }

    func testInternetPWQuery() {
        // given/when
        let pwQuery = InternetPasswordQuery(server: "test.example.com")
            .matching(account: "Self Service - no user")
            .matching(port: 8000)
            .matching(group: 24)

        // then
        let actual = pwQuery.query
        XCTAssertEqual(actual.count, 5)
        XCTAssertEqual(actual[kSecClass as String] as! CFString, kSecClassInternetPassword)
        XCTAssertEqual(actual[kSecAttrServer as String] as! String, "test.example.com")
        XCTAssertEqual(actual[kSecAttrAccount as String] as! String, "Self Service - no user")
        XCTAssertEqual(actual[kSecAttrPort as String] as! Int, 8000)
        XCTAssertEqual(actual[kSecAttrType as String] as! Int, 24)
    }
}
