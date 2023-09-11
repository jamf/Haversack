// SPDX-License-Identifier: MIT
// Copyright 2023, Jamf

import XCTest
import Haversack

#if os(macOS)

final class GenericPasswordIntegrationTests: XCTestCase {
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

    func testSaveOverExistingGenericPassword() throws {
        // given
        let customData = try XCTUnwrap("some test".data(using: .utf8))
        let givenPassword = GenericPasswordEntity()
        givenPassword.customData = customData
        givenPassword.passwordData = "top secret".data(using: .utf8)
        try haversack.save(givenPassword, itemSecurity: .standard, updateExisting: false)
        defer {
            // delete the item before we are done.
            try? haversack.delete(givenPassword)
        }

        // when - we try to overwrite the password with a new value.
        let newPassword = GenericPasswordEntity()
        newPassword.customData = customData
        newPassword.passwordData = "new secret".data(using: .utf8)
        try haversack.save(newPassword, itemSecurity: .standard, updateExisting: true)

        // then - the new password data is in the keychain
        let pwQuery = GenericPasswordQuery()
            .matching(customData: customData)
            .returning([.data, .attributes])
        let password = try haversack.first(where: pwQuery)

        XCTAssertEqual(password.customData, customData)
        XCTAssertEqual(password.passwordData, newPassword.passwordData)
    }
}

#else

#warning("Requires test host keychain entitlement")

#endif
