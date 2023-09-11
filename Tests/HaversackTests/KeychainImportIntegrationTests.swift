// SPDX-License-Identifier: MIT
// Copyright 2023, Jamf

import XCTest
import Haversack
import HaversackMock

#if os(macOS)
final class KeychainImportTests: XCTestCase {
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

    func testImportCertificate() throws {
        // Given
        let url = getURLForTestResource(named: "cert.cer")
        let data = try Data(contentsOf: url)

        let config = KeychainImportConfig<CertificateEntity>()

        // When
        let items = try haversack.importItems(data, config: config)

        // Then
        let cert = try XCTUnwrap(items.first)
        XCTAssertNotNil(cert.reference)

        // Make sure the item was actually imported to the keychain
        let query = CertificateQuery(label: "Test Jamf Certificate").returning(.attributes)
        let entity = try haversack.first(where: query)

        XCTAssertNotNil(entity.issuerStrings)

        // Clean up
        try haversack.delete(entity)
    }

    func testImportKey() throws {
        // Given
        let data = try Data(contentsOf: getURLForTestResource(named: "key.bsafe"))

        // When
        let config = KeychainImportConfig<KeyEntity>().inputFormat(.formatBSAFE)
        let items = try haversack.importItems(data, config: config)

        // Then
        XCTAssertEqual(items.count, 1)

        let importedKey = try XCTUnwrap(items.first)
        XCTAssertNotNil(importedKey.reference)

        // Clean up
        try haversack.delete(where: KeyQuery(label: "Imported Private Key"))
    }

    func testImportIdentity() throws {
        // Given
        let exportedFileName = "identity.p12"
        let url = getURLForTestResource(named: exportedFileName)
        let data = try Data(contentsOf: url)

        let config = KeychainImportConfig<IdentityEntity>()
            .fileNameOrExtension(exportedFileName)
            .passphraseStrategy(.useProvided({ "somesecurepassphrase" }))

        // When
        let items = try haversack.importItems(data, config: config)

        // Then
        // We should have a single IdentityEntity in the array
        XCTAssertEqual(items.count, 1)

        // The identity should have been imported to the keychain
        let query = IdentityQuery(label: "Test Certificate").returning(.reference)
        let entity = try haversack.first(where: query)
        let identity = try XCTUnwrap(entity.reference)

        // There should be a certificate
        var certificate: SecCertificate?
        let certCopyResult = SecIdentityCopyCertificate(identity, &certificate)

        XCTAssertEqual(certCopyResult, errSecSuccess)
        XCTAssertNotNil(certificate)

        // There should be a private key
        var privateKey: SecKey?
        let privateKeyCopyResult = SecIdentityCopyPrivateKey(identity, &privateKey)

        XCTAssertEqual(privateKeyCopyResult, errSecSuccess)
        XCTAssertNotNil(privateKey)

        // Clean up
        try haversack.delete(entity)
    }

    func testImportNoKeychain() throws {
        // Given
        let url = getURLForTestResource(named: "cert.cer")
        let data = try Data(contentsOf: url)

        let config = try KeychainImportConfig<CertificateEntity>()
            .returnEntitiesWithoutSaving()

        // When
        let items = try haversack.importItems(data, config: config)

        // Then
        let cert = try XCTUnwrap(items.first)
        XCTAssertNotNil(cert.reference)

        // Make sure the item wasn't actually imported to the keychain
        let query = CertificateQuery(label: "Test Jamf Certificate")
        XCTAssertThrowsError(try haversack.first(where: query))
    }
}
#endif
