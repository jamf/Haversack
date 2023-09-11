// SPDX-License-Identifier: MIT
// Copyright 2023, Jamf

import XCTest
import Haversack

#if os(macOS)

final class InternetPasswordIntegrationTests: XCTestCase {
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

    /// Remove the "a" from the front of this function's name to recreate the unit_tests.keychain file and update/add new items to it.
    func atestCreateOrOpenKeychainFile() throws {
        // given
        let keychainFile = try XCTUnwrap(haversack.configuration.keychain)

        // when
        try keychainFile.attemptToOpenOrCreate()

        // then
        let newPassword = InternetPasswordEntity()
        newPassword.authenticationType = .HTTPDigest
        newPassword.account = "Chewbacca"
        newPassword.path = "falcon/holotable"
        newPassword.label = "unit test password"
        newPassword.passwordData = "RAAWR GRAWR".data(using: .utf8)
        newPassword.port = 443
        newPassword.protocol = .HTTPS
        newPassword.server = "test.example.com"

        let savedPassword = try haversack.save(newPassword, itemSecurity: .standard, updateExisting: true)

        XCTAssertNotNil(savedPassword)

        let genericPassword = GenericPasswordEntity()
        genericPassword.account = "Mac Custom File tests"
        genericPassword.service = "General Han Solo"
        genericPassword.comment = "You know, sometimes I amaze myself"
        genericPassword.label = "the general password"
        genericPassword.passwordData = "never tell me the odds".data(using: .utf8)

        let savedGenericPW = try haversack.save(genericPassword, itemSecurity: .standard, updateExisting: true)

        XCTAssertNotNil(savedGenericPW)
    }

    func testInternetPWSearchReference() throws {
        // given
        let pwQuery = InternetPasswordQuery(server: "test.example.com")
            .matching(account: "Chewbacca")
            .returning(.reference)

        // when
        let password = try haversack.first(where: pwQuery)

        // then
        XCTAssertNotNil(password.reference)
    }

    func testInternetPWSearchPersistentReference() throws {
        // given
        let pwQuery = InternetPasswordQuery(server: "test.example.com")
            .matching(account: "Chewbacca")
            .returning(.persistantReference)

        // when
        let password = try haversack.first(where: pwQuery)

        // then
        XCTAssertNotNil(password.persistentRef)
    }

    func testInternetPWSearchAttributes() throws {
        // given
        let pwQuery = InternetPasswordQuery(server: "test.example.com")
            .matching(account: "Chewbacca")
            .returning([.attributes, .persistantReference, .reference])

        // when
        let password = try haversack.first(where: pwQuery)

        // then
        XCTAssertEqual(password.server, "test.example.com")
        XCTAssertEqual(password.account, "Chewbacca")
        XCTAssertEqual(password.protocol, .HTTPS)
        XCTAssertEqual(password.authenticationType, .HTTPDigest)
        XCTAssertEqual(password.path, "falcon/holotable")
    }

    func testInternetPWSearchAsyncAttributes() throws {
        // given
        let pwQuery = InternetPasswordQuery(server: "test.example.com")
            .matching(account: "Chewbacca")
            .returning(.attributes)
        let queryFinished = expectation(description: "search finished")
        var queryResult: InternetPasswordEntity?

        // when
        haversack.first(where: pwQuery, completionQueue: .main) { (result) in
            if case .success(let entity) = result {
                queryResult = entity
            } else if case .failure(let error) = result {
                XCTFail("Had .failure from search: \(error)")
            }
            queryFinished.fulfill()
        }
        wait(for: [queryFinished], timeout: 20)

        // then
        let password = try XCTUnwrap(queryResult)
        XCTAssertEqual(password.server, "test.example.com")
        XCTAssertEqual(password.account, "Chewbacca")
        XCTAssertEqual(password.protocol, .HTTPS)
        XCTAssertEqual(password.authenticationType, .HTTPDigest)
        XCTAssertEqual(password.path, "falcon/holotable")
    }

    func testAddInternetPW() throws {
        // given
        let newPassword = InternetPasswordEntity()
        newPassword.protocol = .HTTPS
        newPassword.server = "testing.example.com"
        newPassword.account = "mine too"
        newPassword.label = "sample password"
        newPassword.passwordData = "top secret".data(using: .utf8)
        // Use login keychain
        let haversack = Haversack()

        // when
        let savedPassword = try haversack.save(newPassword, itemSecurity: .standard, updateExisting: true)

        // then
        XCTAssertNotNil(savedPassword)

        // delete the item before we are done.
        try haversack.delete(newPassword)
    }

    func testUpdateInternetPWExistingThrows() throws {
        // given
        let newPassword = InternetPasswordEntity()
        newPassword.protocol = .HTTPS
        newPassword.server = "update.example.com"
        newPassword.account = "mine too"
        newPassword.label = "sample password"
        newPassword.passwordData = "top secret".data(using: .utf8)
        // Use login keychain
        let haversack = Haversack()
        let savedPassword = try haversack.save(newPassword, itemSecurity: .standard, updateExisting: true)
        defer {
            // delete the item before we are done.
            try? haversack.delete(savedPassword)
        }

        // when
        let attemptToUpdate = InternetPasswordEntity()
        attemptToUpdate.protocol = .HTTPS
        attemptToUpdate.server = "update.example.com"
        attemptToUpdate.account = "mine too"
        attemptToUpdate.label = "sample password"
        attemptToUpdate.passwordData = "newer password".data(using: .utf8)

        // when/then
        XCTAssertThrowsError(try haversack.save(attemptToUpdate, itemSecurity: .standard, updateExisting: false),
                             "Should throw because it already exists and we don't want to update the existing item")
    }

    func testUpdateInternetPW() throws {
        // given
        let newPassword = InternetPasswordEntity()
        newPassword.protocol = .HTTPS
        newPassword.server = "update.example.com"
        newPassword.account = "mine too"
        newPassword.label = "sample password"
        newPassword.passwordData = "top secret".data(using: .utf8)
        // Use login keychain
        let haversack = Haversack()
        let savedPassword = try haversack.save(newPassword, itemSecurity: .standard, updateExisting: true)
        defer {
            // delete the item before we are done.
            try? haversack.delete(savedPassword)
        }

        let attemptToUpdate = InternetPasswordEntity()
        attemptToUpdate.protocol = .HTTPS
        attemptToUpdate.server = "update.example.com"
        attemptToUpdate.account = "mine too"
        attemptToUpdate.label = "sample password"
        attemptToUpdate.passwordData = "newer password".data(using: .utf8)

        // when/then
        _ = try haversack.save(attemptToUpdate, itemSecurity: .standard, updateExisting: true)

        // then
        let query = InternetPasswordQuery(server: "update.example.com")
                    .returning(.data)
        let actual = try haversack.first(where: query)

        XCTAssertEqual(actual.passwordData, "newer password".data(using: .utf8))
    }

    func testInternetPWMatchLabelFirst() throws {
        // given
        let newPassword = InternetPasswordEntity()
        newPassword.label = "The test label"
        newPassword.passwordData = "top secret".data(using: .utf8)
        // Use login keychain
        let haversack = Haversack()
        let savedPassword = try haversack.save(newPassword, itemSecurity: .standard, updateExisting: false)
        defer {
            // delete the item before we are done.
            try? haversack.delete(savedPassword)
        }

        let pwQuery = InternetPasswordQuery()
            .matching(label: "The test label")
            .returning(.reference)

        // when
        let password = try haversack.first(where: pwQuery)

        // then
        XCTAssertNotNil(password.reference)
    }

    func testInternetPWMatchLabelSearch() throws {
        // given
        let newPassword = InternetPasswordEntity()
        newPassword.label = "The test label"
        newPassword.passwordData = "top secret".data(using: .utf8)
        // Use login keychain
        let haversack = Haversack()
        let savedPassword = try haversack.save(newPassword, itemSecurity: .standard, updateExisting: false)
        defer {
            // delete the item before we are done.
            try? haversack.delete(savedPassword)
        }

        let pwQuery = InternetPasswordQuery()
            .matching(label: "The test label")
            .returning(.reference)

        // when
        let passwords = try haversack.search(where: pwQuery)

        // then
        XCTAssertEqual(passwords.count, 1)
        XCTAssertNotNil(passwords[0].reference)
    }

    func testInternetPWFirstForDataWorks() throws {
        // given
        let newPassword = InternetPasswordEntity()
        newPassword.label = "The test label"
        newPassword.passwordData = "top secret".data(using: .utf8)
        // Use login keychain
        let haversack = Haversack()
        let savedPassword = try haversack.save(newPassword, itemSecurity: .standard, updateExisting: false)
        defer {
            // delete the item before we are done.
            try? haversack.delete(savedPassword)
        }

        let pwQuery = InternetPasswordQuery()
            .matching(label: "The test label")
            .returning(.data)

        // when
        let password = try haversack.first(where: pwQuery)

        // then
        let pwData = try XCTUnwrap(password.passwordData)
        XCTAssertEqual(pwData, "top secret".data(using: .utf8))
    }

    func testInternetPWSearchForDataThrows() throws {
        let pwQuery = InternetPasswordQuery(server: "the server")
            .returning(.data)

        // when
        XCTAssertThrowsError(try haversack.search(where: pwQuery), "what?") { (error: Error) in
            if let hvError = error as? HaversackError,
               case .notPossible(let string) = hvError {
                XCTAssertEqual(string, "Search for multiple password items cannot return password data; use .first(where:) to find one password item or .returning(.persistentRef) or .returning(.reference) to find multiple items without password data")
            } else {
                XCTFail("error should be a `HaversackError.notPossible` but is \(error)")
            }
        }
    }
}

#else

#warning("Requires test host keychain entitlement")

#endif
