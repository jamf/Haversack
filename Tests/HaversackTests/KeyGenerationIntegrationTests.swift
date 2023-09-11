// SPDX-License-Identifier: MIT
// Copyright 2023, Jamf

import XCTest
import Haversack

#if os(macOS)

final class KeyGenerationIntegrationTests: XCTestCase {
    var haversack: Haversack!

    override func setUp() {
        let testURL = getURLForTestResource(named: "unit_tests.keychain")
        let keychainFile = KeychainFile(at: testURL.path) { _ in
            "abcde12345"
        }
        let config = HaversackConfiguration(keychain: keychainFile)
        haversack = Haversack(configuration: config)
    }

    override func tearDown() {
        haversack = nil
    }

    func testGenerateBasicKey() throws {
        // given
        let theTag = try XCTUnwrap("Unit Test Tag".data(using: .utf8))
        let keyInfo = KeyGenerationConfig(algorithm: .RSA, keySize: 1024)
            .labeled("My Key")
            .tagged(theTag)
            .privateKey(usage: .canDecrypt)

        // when
        let newKey = try haversack.generateKey(fromConfig: keyInfo, itemSecurity: .standard)

        // then
        XCTAssertNotNil(newKey)

        let query = KeyQuery().matching(tag: theTag)
            .returning([.attributes, .reference])
        let actual = try haversack.first(where: query)

        XCTAssertEqual(actual.label, "My Key")
        XCTAssertEqual(actual.tag, theTag)

        // delete the item before we are done.
        try haversack.delete(actual)
    }

    func testGenerateBasicKeyAsync() throws {
        // given
        let theTag = try XCTUnwrap("Unit Testing Tag".data(using: .utf8))
        let keyInfo = KeyGenerationConfig(algorithm: .RSA, keySize: 2048)
            .labeled("Async Key")
            .tagged(theTag)
        let keyGenerated = expectation(description: "new key has been generated")
        var newKey: SecKey?

        // when
        haversack.generateKey(fromConfig: keyInfo, itemSecurity: .standard,
                                               completionQueue: .main) { result in
            if case .success(let key) = result {
                newKey = key
            } else if case .failure(let error) = result {
                XCTFail("Had .failure from generateKey: \(error)")
            }
            keyGenerated.fulfill()
        }
        wait(for: [keyGenerated], timeout: 20)

        // then
        XCTAssertNotNil(newKey)

        let query = KeyQuery().matching(tag: theTag).returning([.attributes, .reference])
        let actual = try haversack.first(where: query)

        XCTAssertEqual(actual.label, "Async Key")
        XCTAssertEqual(actual.tag, theTag)

        // delete the item before we are done.
        try haversack.delete(actual)
    }
}

#else

#warning("Requires test host keychain entitlement")

#endif
