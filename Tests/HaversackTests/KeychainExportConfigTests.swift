// SPDX-License-Identifier: MIT
// Copyright 2023, Jamf

import XCTest
@testable import Haversack

#if os(macOS)
final class KeychainExportConfigTests: XCTestCase {
    func testExportConfig() throws {
        // Given
        let expectedAlertTitle = "Some title"
        let expectedAlertPrompt = "Some prompt"
        let configuration = KeychainExportConfig(outputFormat: .formatPKCS12)
            .PEMArmored()
            .passphraseStrategy(.promptUser(prompt: expectedAlertPrompt, title: expectedAlertTitle))

        // Then
        let actualAlertTitle = try XCTUnwrap(configuration.keyParameters.alertTitle).takeRetainedValue() as String
        let actualAlertPrompt = try XCTUnwrap(configuration.keyParameters.alertPrompt).takeRetainedValue() as String

        XCTAssertEqual(actualAlertTitle, expectedAlertTitle)
        XCTAssertEqual(actualAlertPrompt, expectedAlertPrompt)
        XCTAssertEqual(configuration.flags, .pemArmour)
        XCTAssertEqual(configuration.keyParameters.flags, .securePassphrase)
    }

    func testExportConfigWithPassphrases() throws {
        // Given
        let expectedPassphrase = "somesecurepassphrase"
        let configuration = KeychainExportConfig(outputFormat: .formatPKCS12)
            .passphraseStrategy(.useProvided({ expectedPassphrase }))

        // Then
        let actualPassphrase = try XCTUnwrap(configuration.keyParameters.passphrase).takeRetainedValue() as! CFString
        XCTAssertEqual(actualPassphrase as String, expectedPassphrase)
    }

    func testExportConfigDuplicateModifiers() throws {
        // Given
        let expectedAlertTitle = "The second title"
        let configuration = KeychainExportConfig(outputFormat: .formatPKCS12)
            .passphraseStrategy(.promptUser(prompt: "", title: "The first alert title"))
            .passphraseStrategy(.promptUser(prompt: "", title: expectedAlertTitle))
            .PEMArmored()
            .PEMArmored()

        // Then
        let actualAlertTitle = try XCTUnwrap(configuration.keyParameters.alertTitle).takeRetainedValue() as String
        XCTAssertEqual(actualAlertTitle, expectedAlertTitle)
        XCTAssertEqual(configuration.flags, .pemArmour)
    }
}
#endif
