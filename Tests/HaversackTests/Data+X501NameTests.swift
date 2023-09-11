// SPDX-License-Identifier: MIT
// Copyright 2023, Jamf

import OrderedCollections
import XCTest
@testable import Haversack

final class DataX501NameTests: XCTestCase {
    // Taken from an existing keychain item query result
    static let issuerDataString = "MGIxCzAJBgNVBAYTAlVTMRMwEQYDVQQKEwpBUFBMRSBJTkMuMSYwJAYDVQQLEx1BUFBMRSBDRVJUSUZJQ0FUSU9OIEFVVEhPUklUWTEWMBQGA1UEAxMNQVBQTEUgUk9PVCBDQQ=="

    // Taken from an existing keychain item query result
    static let subjectDataString = "MIGWMQswCQYDVQQGEwJVUzETMBEGA1UECgwKQXBwbGUgSW5jLjEsMCoGA1UECwwjQXBwbGUgV29ybGR3aWRlIERldmVsb3BlciBSZWxhdGlvbnMxRDBCBgNVBAMMO0FwcGxlIFdvcmxkd2lkZSBEZXZlbG9wZXIgUmVsYXRpb25zIENlcnRpZmljYXRpb24gQXV0aG9yaXR5"

    func testDecodeIssuerData() throws {
        // given
        let issuerData = try XCTUnwrap(Data(base64Encoded: Self.issuerDataString))
        let expected: OrderedDictionary = ["2.5.4.6": "US",
                                           "2.5.4.10": "APPLE INC.",
                                           "2.5.4.11": "APPLE CERTIFICATION AUTHORITY",
                                           "2.5.4.3": "APPLE ROOT CA"]

        // when
        let actual = issuerData.decodeASN1Names()

        // then
        XCTAssertEqual(actual, expected)
    }

    func testDecodeSubjectData() throws {
        // given
        let subjectData = try XCTUnwrap(Data(base64Encoded: Self.subjectDataString))
        let expected: OrderedDictionary = ["2.5.4.6": "US",
                                           "2.5.4.10": "Apple Inc.",
                                           "2.5.4.11": "Apple Worldwide Developer Relations",
                                           "2.5.4.3": "Apple Worldwide Developer Relations Certification Authority"]

        // when
        let actual = subjectData.decodeASN1Names()

        // then
        XCTAssertEqual(actual, expected)
    }

    func testDecodeEncodeRoundTrip() throws {
        // given
        let issuerData = try XCTUnwrap(Data(base64Encoded: Self.issuerDataString))

        // when
        let decoded = issuerData.decodeASN1Names()
        let encoded = Data.makeASN1EncodedName(from: decoded)

        // then
        XCTAssertEqual(issuerData, encoded)
        let base64 = encoded.base64EncodedString()
        XCTAssertEqual(base64, Self.issuerDataString)
    }

    func testDecodeSubjectSimpleData() throws {
        // given
        let subjectData = try XCTUnwrap(Data(base64Encoded: "MEYxRDBCBgNVBAMMO0FwcGxlIFdvcmxkd2lkZSBEZXZlbG9wZXIgUmVsYXRpb25zIENlcnRpZmljYXRpb24gQXV0aG9yaXR5"))
        let expected: OrderedDictionary = ["2.5.4.3": "Apple Worldwide Developer Relations Certification Authority"]

        // when
        let actual = subjectData.decodeASN1Names()

        // then
        XCTAssertEqual(actual, expected)
    }

    func testEncodeSubjectData() throws {
        // given
        let dataToEncode: OrderedDictionary = ["2.5.4.10": "Apple Inc.",
                            "2.5.4.3": "Apple Worldwide Developer Relations Certification Authority",
                            "2.5.4.6": "US",
                            "2.5.4.11": "Apple Worldwide Developer Relations"]

        // when
        let actual = Data.makeASN1EncodedName(from: dataToEncode)

        // then
        XCTAssertEqual(actual.count, 153, "We should have exactly 153 bytes of data")

        let decoded = actual.decodeASN1Names()
        XCTAssertEqual(decoded, dataToEncode, "Our code should be able to decode the ASN.1 data")
    }

    func testEncodeSubjectDataExtraLong() throws {
        // given
        let dataToEncode: OrderedDictionary = ["2.5.4.10": "Apple Inc.",
                            "2.5.4.3": "Apple Worldwide Developer Relations Certification Authority",
                            "2.5.4.6": "US",
                            "2.5.4.11": "Apple Worldwide Developer Relations",
                            "2.5.4.1": "Apple Inc.",
                            "2.5.4.2": "Apple Worldwide Developer Relations Certification Authority",
                            "2.5.4.8": "US",
                            "2.5.4.12": "Apple Worldwide Developer Relations",
                            "2.5.4.4": "Apple Inc.",
                            "2.5.4.5": "Apple Worldwide Developer Relations Certification Authority",
                            "2.5.4.7": "US",
                            "2.5.4.9": "Apple Worldwide Developer Relations"]

        // when
        let actual = Data.makeASN1EncodedName(from: dataToEncode)

        // then
        XCTAssertEqual(actual.count, 454, "We should have exactly 454 bytes of data")

        let decoded = actual.decodeASN1Names()
        XCTAssertEqual(decoded, dataToEncode, "Our code should be able to decode the ASN.1 data")
    }
}
