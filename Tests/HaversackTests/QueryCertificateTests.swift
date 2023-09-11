// SPDX-License-Identifier: MIT
// Copyright 2023, Jamf

import XCTest
import Haversack

final class QueryCertificateTests: XCTestCase {
#if os(macOS)
    func testCertQueryMac() {
        // given/when
        let certQuery = CertificateQuery(label: "ImportantCert")
            .stringMatching(options: [.caseInsensitive])
            .matching(email: "test@jamf.com")
            .matchingSubject(.contains, "Jamf")
            .matchingSubject(.startsWith, "Test")
            .matchingSubject(.endsWith, "Certificate")
            .matchingSubject(.isExactly, "Test Jamf Certificate")
            .matching(mustBeValidOnDate: NSDate() as Date)
            .trustedOnly()
            .returning(.attributes)

        // then
        let actual = certQuery.query
        XCTAssertEqual(actual.count, 11)
        XCTAssertEqual(actual[kSecClass as String] as! CFString, kSecClassCertificate)
        XCTAssertEqual(actual[kSecAttrLabel as String] as! String, "ImportantCert")
        XCTAssertEqual(actual[kSecMatchCaseInsensitive as String] as! Bool, true)
        XCTAssertEqual(actual[kSecMatchEmailAddressIfPresent as String] as! String, "test@jamf.com")
        XCTAssertEqual(actual[kSecReturnAttributes as String] as! Bool, true)
    }
#endif

    func testCertQuery() {
        // given/when
        let certQuery = CertificateQuery(label: "ImportantCert")
            .stringMatching(options: [.caseInsensitive])
            .matching(email: "test@jamf.com")
            .matchingSubject(.contains, "Jamf")
            .matching(mustBeValidOnDate: NSDate() as Date)
            .trustedOnly()
            .returning(.attributes)

        // then
        let actual = certQuery.query
        XCTAssertEqual(actual.count, 8)
        XCTAssertEqual(actual[kSecClass as String] as! CFString, kSecClassCertificate)
        XCTAssertEqual(actual[kSecAttrLabel as String] as! String, "ImportantCert")
        XCTAssertEqual(actual[kSecMatchCaseInsensitive as String] as! Bool, true)
        XCTAssertEqual(actual[kSecMatchEmailAddressIfPresent as String] as! String, "test@jamf.com")
        XCTAssertEqual(actual[kSecReturnAttributes as String] as! Bool, true)
    }
}
