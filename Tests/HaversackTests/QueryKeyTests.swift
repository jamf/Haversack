// SPDX-License-Identifier: MIT
// Copyright 2023, Jamf

import XCTest
import Haversack

final class QueryKeyTests: XCTestCase {
    func testKeyQueryNoLabel() throws {
        // when
        let keyQuery = KeyQuery()
            .returning(.reference)

        // then
        let actual = keyQuery.query
        XCTAssertEqual(actual.count, 2)
        XCTAssertEqual(actual[kSecClass as String] as! CFString, kSecClassKey)
        XCTAssertTrue(actual[kSecReturnRef as String] as! Bool)
    }

    func testKeyQueryByTag() throws {
        // given
        let haversack = Haversack()

        let testTag = try XCTUnwrap("what".data(using: .utf8))
        let keyQuery = KeyQuery(label: "Testing Key")
            .matching(tag: testTag)
            .returning(.reference)

        // when/then
        XCTAssertThrowsError(try haversack.first(where: keyQuery), "Unfound item")
    }

    func testKeyQueryByKeyClass() throws {
        // when
        let keyQuery = KeyQuery(label: "KeyClass Key")
            .matching(keyClass: .private)
            .returning(.reference)

        // then
        let actual = keyQuery.query
        XCTAssertEqual(actual.count, 4)
        XCTAssertEqual(actual[kSecClass as String] as! CFString, kSecClassKey)
        XCTAssertEqual(actual[kSecAttrKeyClass as String] as! CFString, kSecAttrKeyClassPrivate)
        XCTAssertEqual(actual[kSecAttrLabel as String] as! String, "KeyClass Key")
        XCTAssertTrue(actual[kSecReturnRef as String] as! Bool)
    }

    func testKeyQueryByKeyType() throws {
        // when
        let keyQuery = KeyQuery(label: "KeyType Key")
            .matching(keyAlgorithm: .RSA)
            .returning(.reference)

        // then
        let actual = keyQuery.query
        XCTAssertEqual(actual.count, 4)
        XCTAssertEqual(actual[kSecClass as String] as! CFString, kSecClassKey)
        XCTAssertEqual(actual[kSecAttrKeyType as String] as! CFString, kSecAttrKeyTypeRSA)
        XCTAssertEqual(actual[kSecAttrLabel as String] as! String, "KeyType Key")
        XCTAssertTrue(actual[kSecReturnRef as String] as! Bool)
    }

    func testKeyQueryInSecureEnclave() throws {
        // when
        let keyQuery = KeyQuery(label: "SE Key")
            .inSecureEnclave()
            .returning(.attributes)

        // then
        let actual = keyQuery.query
        XCTAssertEqual(actual.count, 4)
        XCTAssertEqual(actual[kSecClass as String] as! CFString, kSecClassKey)
        XCTAssertEqual(actual[kSecAttrTokenID as String] as! CFString, kSecAttrTokenIDSecureEnclave)
        XCTAssertEqual(actual[kSecAttrLabel as String] as! String, "SE Key")
        XCTAssertTrue(actual[kSecReturnAttributes as String] as! Bool)
    }

    func testKeyQueryByKeySize() throws {
        // when
        let keyQuery = KeyQuery(label: "Sized Key")
            .matching(keySizeInBits: 2048)
            .returning(.persistantReference)

        // then
        let actual = keyQuery.query
        XCTAssertEqual(actual.count, 4)
        XCTAssertEqual(actual[kSecClass as String] as! CFString, kSecClassKey)
        XCTAssertEqual(actual[kSecAttrKeySizeInBits as String] as! Int, 2048)
        XCTAssertEqual(actual[kSecAttrLabel as String] as! String, "Sized Key")
        XCTAssertTrue(actual[kSecReturnPersistentRef as String] as! Bool)
    }

    func testKeyQueryByEffectiveKeySize() throws {
        // when
        let keyQuery = KeyQuery(label: "Effectively Sized Key")
            .matching(effectiveKeySize: 4096)
            .returning(.persistantReference)

        // then
        let actual = keyQuery.query
        XCTAssertEqual(actual.count, 4)
        XCTAssertEqual(actual[kSecClass as String] as! CFString, kSecClassKey)
        XCTAssertEqual(actual[kSecAttrEffectiveKeySize as String] as! Int, 4096)
        XCTAssertEqual(actual[kSecAttrLabel as String] as! String, "Effectively Sized Key")
        XCTAssertTrue(actual[kSecReturnPersistentRef as String] as! Bool)
    }

    func testKeyQueryByKeyUsage() throws {
        // when
        let keyQuery = KeyQuery(label: "Usage Key")
            .matching(keyUsage: [.canSign, .canDecrypt])
            .returning(.persistantReference)

        // then
        let actual = keyQuery.query
        XCTAssertEqual(actual.count, 5)
        XCTAssertEqual(actual[kSecClass as String] as! CFString, kSecClassKey)
        XCTAssertTrue(actual[kSecAttrCanSign as String] as! Bool)
        XCTAssertTrue(actual[kSecAttrCanDecrypt as String] as! Bool)
        XCTAssertEqual(actual[kSecAttrLabel as String] as! String, "Usage Key")
        XCTAssertTrue(actual[kSecReturnPersistentRef as String] as! Bool)
    }

    func testKeyQueryByAppLabel() throws {
        // given
        let myLabel = try XCTUnwrap("Haversack Unit Testing".data(using: .utf8))

        // when
        let keyQuery = KeyQuery(label: "App Label Key")
            .matching(appLabel: myLabel)
            .returning(.persistantReference)

        // then
        let actual = keyQuery.query
        XCTAssertEqual(actual.count, 4)
        XCTAssertEqual(actual[kSecClass as String] as! CFString, kSecClassKey)
        XCTAssertEqual(actual[kSecAttrApplicationLabel as String] as! Data, myLabel)
        XCTAssertEqual(actual[kSecAttrLabel as String] as! String, "App Label Key")
        XCTAssertTrue(actual[kSecReturnPersistentRef as String] as! Bool)
    }

    func testKeyQueryByLegacyAppLabel() throws {
        // given
        let myLabel = "Haversack Legacy Testing"

        // when
        let keyQuery = KeyQuery(label: "Legacy Key")
            .matching(legacyAppLabel: myLabel)
            .returning(.data)

        // then
        let actual = keyQuery.query
        XCTAssertEqual(actual.count, 4)
        XCTAssertEqual(actual[kSecClass as String] as! CFString, kSecClassKey)
        XCTAssertEqual(actual[kSecAttrApplicationLabel as String] as! String, myLabel)
        XCTAssertEqual(actual[kSecAttrLabel as String] as! String, "Legacy Key")
        XCTAssertTrue(actual[kSecReturnData as String] as! Bool)
    }
}
