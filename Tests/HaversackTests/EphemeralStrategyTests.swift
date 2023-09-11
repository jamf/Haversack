// SPDX-License-Identifier: MIT
// Copyright 2023, Jamf

import XCTest
import Haversack
import HaversackMock

final class EphemeralStrategyTests: XCTestCase {
    func testInternetPWSearchReferenceMock() throws {
        // given
        let mock = HaversackEphemeralStrategy()
        let expectedEntity = InternetPasswordEntity()
        expectedEntity.protocol = .appleTalk
        mock.mockData["acctlukeclassinetm_Limitm_Lir_Refsrvrstas"] = expectedEntity
        let config = HaversackConfiguration(strategy: mock)
        let haversack = Haversack(configuration: config)

        let pwQuery = InternetPasswordQuery(server: "stash")
            .matching(account: "luke")
            .returning(.reference)

        // when
        let password = try haversack.first(where: pwQuery)

        // then
        XCTAssertNotNil(password)
        XCTAssertEqual(password.protocol, .appleTalk)
    }

    func testGenericPWSearchReferenceMock() throws {
        // given
        let testService = "unit.test"
        let mock = HaversackEphemeralStrategy()
        let expectedEntity = GenericPasswordEntity()
        expectedEntity.service = testService
        mock.mockData["classgenpm_Limitm_Lir_Refsvceunit"] = expectedEntity
        let config = HaversackConfiguration(strategy: mock)
        let haversack = Haversack(configuration: config)

        let pwQuery = GenericPasswordQuery(service: testService)
            .returning(.reference)

        // when
        let password = try haversack.first(where: pwQuery)

        // then
        XCTAssertNotNil(password)
        XCTAssertEqual(password.service, testService)
    }

    #if os(macOS)
    func testImportItemsIncorrectMockEntities() throws {
        // Given
        let mock = HaversackEphemeralStrategy()
        mock.mockImportedEntities = [ KeyEntity() ]

        let haversack = Haversack(configuration: HaversackConfiguration(strategy: mock))
        let importConfig = KeychainImportConfig<CertificateEntity>()

        // When
        XCTAssertThrowsError(try haversack.importItems(Data(), config: importConfig))

        // Then
        XCTAssertNotNil(mock.certificateImportConfiguration)
    }
    #endif
}
