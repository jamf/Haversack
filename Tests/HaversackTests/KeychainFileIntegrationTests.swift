// SPDX-License-Identifier: MIT
// Copyright 2023, Jamf

import Foundation

import XCTest
import Haversack

#if os(macOS)

final class KeychainFileIntegrationTests: XCTestCase {
    func testSimpleFileCreation() throws {
        // given
        let keychainFile = KeychainFile(at: "/tmp/haversack_unit_tests.keychain") { _ in
            "abc"
        }

        // when
        try keychainFile.attemptToOpenOrCreate()

        // then
        let config = HaversackConfiguration(keychain: keychainFile)
        let haversack = Haversack(configuration: config)

        let newPassword = InternetPasswordEntity()
        newPassword.server = "test.example.com"
        newPassword.label = "unit test password"
        newPassword.passwordData = "top secret".data(using: .utf8)

        let savedPassword = try haversack.save(newPassword, itemSecurity: .standard, updateExisting: true)

        XCTAssertNotNil(savedPassword)

        // cleanup
        try keychainFile.delete()
    }

    func testLock() throws {
        // given
        let keychainFile = KeychainFile(at: "/tmp/haversack_unit_test.keychain") { _ in
            "abc"
        }
        try keychainFile.attemptToOpenOrCreate()
        XCTAssertFalse(keychainFile.isLocked, "Keychain files are unlocked when created")

        // when
        try keychainFile.lock()

        // then
        XCTAssertTrue(keychainFile.isLocked, "The keychain should now report as locked")

        try keychainFile.delete()
    }

    func testUnlock() throws {
        // given
        let keychainFile = KeychainFile(at: "/tmp/haversack_unit_test.keychain") { _ in
            "abc"
        }
        try keychainFile.attemptToOpenOrCreate()
        try keychainFile.lock()
        XCTAssertTrue(keychainFile.isLocked, "The keychain should be locked")

        // when
        try keychainFile.unlock()

        // then
        XCTAssertFalse(keychainFile.isLocked, "The keychain should now report as unlocked")

        try keychainFile.delete()
    }
}

#endif
