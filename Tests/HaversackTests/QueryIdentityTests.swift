// SPDX-License-Identifier: MIT
// Copyright 2023, Jamf

import XCTest
import Haversack

final class QueryIdentityTests: XCTestCase {
    func testIdentityQueryNoLabel() {
        // given/when
        let certQuery = IdentityQuery()
            .matching(email: "test@jamf.com")

        // then
        let actual = certQuery.query
        XCTAssertEqual(actual.count, 2)
        XCTAssertEqual(actual[kSecClass as String] as! CFString, kSecClassIdentity)
        XCTAssertEqual(actual[kSecMatchEmailAddressIfPresent as String] as! String, "test@jamf.com")
    }

    func testIdentityQuery() {
        // given/when
        let certQuery = IdentityQuery(label: "Some Identity")

        // then
        let actual = certQuery.query
        XCTAssertEqual(actual.count, 2)
        XCTAssertEqual(actual[kSecClass as String] as! CFString, kSecClassIdentity)
        XCTAssertEqual(actual[kSecAttrLabel as String] as! String, "Some Identity")
    }
}
