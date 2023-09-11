// SPDX-License-Identifier: MIT
// Copyright 2023, Jamf

import XCTest
import Haversack

#if os(macOS)

final class CertificateIntegrationTests: XCTestCase {
    func testCertificateQuery() throws {
        // given
        let certQuery = CertificateQuery()
            .matchingSubject(.contains, "apple")
            .stringMatching(options: [.caseInsensitive])
            .returning([.reference, .attributes])
        let haversack = Haversack()

        // when
        let certificate = try haversack.first(where: certQuery)

        // then
        XCTAssertNotNil(certificate.reference)
    }

    func testCertificateTypeAndEncodingQuery() throws {
        // given
        let certQuery = CertificateQuery()
            .matching(certificateType: .x509v1)
            .matching(certificateEncoding: .der)
            .matching(mustBeValidOnDate: Date())
            .trustedOnly()
            .returning(.attributes)
        let haversack = Haversack()

        // when
        let certificateArray = try haversack.search(where: certQuery)

        // then
        XCTAssertGreaterThan(certificateArray.count, 0)
    }

    func testCertificateSubjectQuery() throws {
        // given
        let certQuery = CertificateQuery()
            .matchingSubject(.contains, "apple")
            .stringMatching(options: .caseInsensitive)
            .returning([.reference, .attributes])
        let haversack = Haversack()

        // when
        let certificateArray = try haversack.search(where: certQuery)

        // then
        XCTAssertGreaterThan(certificateArray.count, 0)
    }

    func testAddCertificate() throws {
        // given
        let certData = try Data(contentsOf: getURLForTestResource(named: "cert.cer"))
        let certRef = try XCTUnwrap(SecCertificateCreateWithData(nil, certData as CFData))
        let newCertificate = CertificateEntity(from: certRef)
        let haversack = Haversack()

        // when
        let savedCert = try haversack.save(newCertificate, itemSecurity: .standard, updateExisting: false)

        // then
        XCTAssertNotNil(savedCert)

        // Delete the certificate before ending.
        let deleteQuery = CertificateQuery().matchingSubject(.isExactly, "Test Jamf Certificate")
        try haversack.delete(where: deleteQuery)
    }

    func testSaveOverExistingCertificate() throws {
        // given - we have a certificate in the keychain
        let haversack = Haversack()

        let certData = try Data(contentsOf: getURLForTestResource(named: "cert.cer"))
        let givenCertRef = try XCTUnwrap(SecCertificateCreateWithData(nil, certData as CFData))
        let givenCertEntity = CertificateEntity(from: givenCertRef)
        try haversack.save(givenCertEntity, itemSecurity: .standard, updateExisting: false)

        defer {
            // we successfully have the cert in the keychain; ensure we delete the cert before ending.
            let deleteQuery = CertificateQuery().matchingSubject(.isExactly, "Test Jamf Certificate")
            try? haversack.delete(where: deleteQuery)
        }

        // when - we try to save a new certificate on top of the existing one
        let certRef = try XCTUnwrap(SecCertificateCreateWithData(nil, certData as CFData))
        let newCertificate2 = CertificateEntity(from: certRef)

        let savedAgain = try haversack.save(newCertificate2, itemSecurity: .standard, updateExisting: true)

        // then
        XCTAssertNotNil(savedAgain)
    }
}

#else

#warning("Requires test host keychain entitlement")

#endif
