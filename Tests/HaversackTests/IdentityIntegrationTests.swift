// SPDX-License-Identifier: MIT
// Copyright 2023, Jamf

import XCTest
import Haversack

#if os(macOS)

final class IdentityIntegrationTests: XCTestCase {
    func atestIdentitySubjectQuery() throws {
        // given
        let identityQuery = IdentityQuery()
            .matchingSubject(.contains, "apple")
            .stringMatching(options: [.caseInsensitive])
            .returning([.reference, .attributes])
        let haversack = Haversack()

        // when
        let identity = try haversack.first(where: identityQuery)

        // then
        XCTAssertNotNil(identity.reference)
    }

    func atestIdentityValidAndTrustedQuery() throws {
        // given
        let identityQuery = IdentityQuery()
            .matching(mustBeValidOnDate: Date())
            .trustedOnly()
            .returning(.attributes)
        let haversack = Haversack()

        // when
        let identityArray = try haversack.search(where: identityQuery)

        // then
        XCTAssertGreaterThan(identityArray.count, 0)
    }

    func atestIdentityQueryIssuerData() throws {
        // given
        let issuerDataString = "MGIxCzAJBgNVBAYTAlVTMRMwEQYDVQQKEwpBUFBMRSBJTkMuMSYwJAYDVQQLEx1BUFBMRSBDRVJUSUZJQ0FUSU9OIEFVVEhPUklUWTEWMBQGA1UEAxMNQVBQTEUgUk9PVCBDQQ=="
        let issuerData = try XCTUnwrap(Data(base64Encoded: issuerDataString))
        let identityQuery = IdentityQuery()
            .matching(issuersData: [issuerData])
            .stringMatching(options: .caseInsensitive)
            .returning([.reference, .attributes])
        let haversack = Haversack()

        // when
       let identityArray = try haversack.search(where: identityQuery)

        // then
        XCTAssertGreaterThan(identityArray.count, 0)
    }

    func atestIdentityQueryIssuers() throws {
        // given
        let identityQuery = IdentityQuery()
            .matching(issuers: [["2.5.4.6": "US",
                                "2.5.4.10": "APPLE INC.",
                                "2.5.4.11": "APPLE CERTIFICATION AUTHORITY",
                                "2.5.4.3": "APPLE ROOT CA"],
                                // Second issuer that will not match anything
                                ["1.2.3.4": "Will Not Be Found"]])
            .stringMatching(options: .caseInsensitive)
            .returning([.reference, .attributes])
        let haversack = Haversack()

        // when
       let identityArray = try haversack.search(where: identityQuery)

        // then
        XCTAssertGreaterThan(identityArray.count, 0)
    }

    func testIdentityQueryIssuersNotFound() throws {
        // given
        let identityQuery = IdentityQuery()
            .matching(issuers: [["1.2.3": "Not found"]])
            .stringMatching(options: .caseInsensitive)
            .returning([.reference, .attributes])
        let haversack = Haversack()

        // when
        XCTAssertThrowsError(try haversack.search(where: identityQuery)) { error in
            // then
            if let hvError = error as? HaversackError {
                switch hvError {
                case .keychainError(let status):
                    XCTAssertEqual(status, errSecItemNotFound)
                default:
                    XCTFail("error should be a .keychainError but is \(error)")
                }
                print(hvError.localizedDescription)
            } else {
                XCTFail("error should be a `HaversackError` but is \(error)")
            }
        }
    }

    func testIdentityKeyBasedQuery() throws {
        // given
        let identityQuery = IdentityQuery()
            .inSecureEnclave()
            .matching(keyUsage: .canDecrypt)
            .returning(.reference)
        let haversack = Haversack()

        // when
        XCTAssertThrowsError(try haversack.search(where: identityQuery)) { error in
            // then
            if let hvError = error as? HaversackError {
                switch hvError {
                case .keychainError(let status):
                    XCTAssertEqual(status, errSecItemNotFound)
                default:
                    XCTFail("error should be a .keychainError but is \(error)")
                }
                print(hvError.localizedDescription)
            } else {
                XCTFail("error should be a `HaversackError` but is \(error)")
            }
        }
    }
}

#else

#warning("Requires test host keychain entitlement")

#endif
