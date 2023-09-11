// SPDX-License-Identifier: MIT
// Copyright 2023, Jamf

import XCTest
import Haversack
import HaversackMock

#if os(macOS)
final class KeychainExportIntegrationTests: XCTestCase {
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

    func testExportKey() throws {
        // Given
        let query = KeyQuery(label: "unit test identity")
            .matching(keyAlgorithm: .RSA)
            .returning(.reference)

        let entity = try haversack.first(where: query)

        let exportConfig = KeychainExportConfig(outputFormat: .formatPKCS12)
            .passphraseStrategy(.useProvided({ "somesecurepassphrase" }))

        // When
        let data = try haversack.exportItems([entity], config: exportConfig)

        // Then
        XCTAssertFalse(data.isEmpty)
    }

    func testExportIdentity() throws {
        // Given
        let query = IdentityQuery(label: "unit test identity").returning(.reference)
        let item = try haversack.first(where: query)

        let config = KeychainExportConfig(outputFormat: .formatPKCS12)
            .passphraseStrategy(.useProvided({ "somesecurepassphrase" }))

        // When
        let data = try haversack.exportItems([item], config: config)

        // Then
        XCTAssertFalse(data.isEmpty)
    }

    func testExportCertificate() throws {
        // Given
        let query = CertificateQuery(label: "unit test identity").returning(.reference)
        let entity = try haversack.first(where: query)

        let exportConfig = KeychainExportConfig(outputFormat: .formatPEMSequence)

        // When
        let data = try haversack.exportItems([entity], config: exportConfig)

        // Then
        XCTAssertFalse(data.isEmpty)
    }

    func testExportItemWithoutReference() throws {
        // Given
        let query = CertificateQuery(label: "unit test identity")
        let entity = try haversack.first(where: query)

        let exportConfig = KeychainExportConfig(outputFormat: .formatPEMSequence)

        // When
        XCTAssertThrowsError(try haversack.exportItems([entity], config: exportConfig), "Exporting a keychain item requires the reference to the item; try using the result of running a Haversack query with .returning(.reference).")
    }
}
#endif
