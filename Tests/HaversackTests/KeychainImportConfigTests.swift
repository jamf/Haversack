// SPDX-License-Identifier: MIT
// Copyright 2023, Jamf

import XCTest
@testable import Haversack

#if os(macOS)
final class KeychainImportConfigTests: XCTestCase {
    func testImportConfig() throws {
        // Given
        let expectedTitle = "Some alert title"
        let expectedPrompt = "Some alert prompt"
        let configuration = try KeychainImportConfig<KeyEntity>()
            .itemType(.itemTypePrivateKey)
            .inputFormat(.formatPKCS12)
            .mustBeEncryptedDuringExport()
            .passphraseStrategy(.promptUser(prompt: expectedPrompt, title: expectedTitle))

        // Then
        XCTAssertEqual(configuration.inputFormat, .formatPKCS12)
        XCTAssertEqual(configuration.itemType, .itemTypePrivateKey)

        let keyParams = try XCTUnwrap(configuration.keyParams)
        let alertTitle = try XCTUnwrap(keyParams.alertTitle?.takeRetainedValue())
        let alertPrompt = try XCTUnwrap(keyParams.alertPrompt?.takeRetainedValue())
        XCTAssertEqual(alertTitle as String, expectedTitle)
        XCTAssertEqual(alertPrompt as String, expectedPrompt)

        let keyAttrs = try XCTUnwrap(keyParams.keyAttributes?.takeRetainedValue()) as [AnyObject]
        let castedKeyAttrs = keyAttrs as! [CFString]
        XCTAssert(castedKeyAttrs.contains(kSecAttrIsSensitive))
        XCTAssertFalse(castedKeyAttrs.contains(kSecAttrIsExtractable))
    }

    func testExtractableWithoutSaving() {
        XCTAssertThrowsError(
            try KeychainImportConfig<KeyEntity>()
                .returnEntitiesWithoutSaving()
                .extractable()
        )
    }

    func testSensitiveWithoutSaving() {
        XCTAssertThrowsError(
            try KeychainImportConfig<KeyEntity>()
                .returnEntitiesWithoutSaving()
                .mustBeEncryptedDuringExport()
        )
    }

    func testKeyImportFlagsWithoutSaving() {
        XCTAssertThrowsError(
            try KeychainImportConfig<KeyEntity>()
                .returnEntitiesWithoutSaving()
                .noAccessControl()
        )

        XCTAssertThrowsError(
            try KeychainImportConfig<KeyEntity>()
                .returnEntitiesWithoutSaving()
                .importOnlyOne()
        )

        XCTAssertThrowsError(
            try KeychainImportConfig<KeyEntity>()
                .returnEntitiesWithoutSaving()
                .noAccessControl()
                .importOnlyOne()
        )
    }

    func testReturnWithoutSavingWithExtractable() {
        XCTAssertThrowsError(
            try KeychainImportConfig<KeyEntity>()
                .mustBeEncryptedDuringExport()
                .returnEntitiesWithoutSaving()
        )
    }
}
#endif
