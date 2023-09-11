// SPDX-License-Identifier: MIT
// Copyright 2023, Jamf

import Foundation
import Haversack
import HaversackMock
import XCTest

final class HaversackTests: XCTestCase {
    var haversack: Haversack!
    var strategy: HaversackEphemeralStrategy!

    private let sampleDomain = "example.com"
    private let sampleEntity: InternetPasswordEntity = {
        let entity = InternetPasswordEntity()
        entity.server = "example.com"
        return entity
    }()
    private let sampleKey: KeyEntity = {
        let entity = KeyEntity()
        entity.label = "example.com"
        entity.keySizeInBits = 2048
        return entity
    }()

    override func setUpWithError() throws {
        let queue = DispatchQueue(label: "haversack.unit_testing", qos: .userInitiated,
                                  target: .global(qos: .userInitiated))
        strategy = HaversackEphemeralStrategy()
        let config = HaversackConfiguration(queue: queue, strategy: strategy)
        haversack = Haversack(configuration: config)
    }

    override func tearDown() {
        strategy = nil
        haversack = nil
    }

#if os(macOS)
    func testCertificateWithComplexSecurityFailsOnMac() throws {
        // given
        let cert = CertificateEntity(from: nil, data: nil, attributes: nil, persistentRef: nil)
        let security = try ItemSecurity().retrievable(when: .complex(.unlocked, .devicePasscode))

        // then
        XCTAssertThrowsError(
            // when
            try self.haversack.save(cert, itemSecurity: security, updateExisting: false)
        )
    }
#endif

    // MARK: -

    func testFirstNoData() throws {
        // given
        let pwQuery = InternetPasswordQuery(server: sampleDomain)

        // when
        XCTAssertThrowsError(try haversack.first(where: pwQuery), "Should not find the item")
    }

    func testFirst() throws {
        // given
        strategy.mockData["classinetm_Limitm_Lir_Datasrvrexam"] = sampleEntity
        let pwQuery = InternetPasswordQuery(server: sampleDomain)

        // when
        let actual = try haversack.first(where: pwQuery)

        // then
        XCTAssertEqual(actual.server, sampleDomain)
    }

    func testFirstAsyncNoData() throws {
        // given
        let pwQuery = InternetPasswordQuery(server: sampleDomain)
        let queryFinished = expectation(description: "search finished")

        // when
        haversack.first(where: pwQuery) { (result) in
            // then
            if case .success(let actual) = result {
                XCTFail("Should have found nothing, but we found \(actual)")
            }
            queryFinished.fulfill()
        }
        wait(for: [queryFinished], timeout: 1)
    }

    func testFirstAsync() throws {
        // given
        strategy.mockData["classinetm_Limitm_Lir_Datasrvrexam"] = sampleEntity
        let pwQuery = InternetPasswordQuery(server: sampleDomain)
        let queryFinished = expectation(description: "search finished")

        // when
        haversack.first(where: pwQuery) { (result) in
            // then
            if case .success(let actual) = result {
                XCTAssertEqual(actual.server, self.sampleDomain)
            } else if case .failure(let error) = result {
                XCTFail("Had .failure from first(where:): \(error)")
            }
            queryFinished.fulfill()
        }
        wait(for: [queryFinished], timeout: 1)
    }

    func testSearchNoData() throws {
        // given
        let pwQuery = InternetPasswordQuery(server: sampleDomain)

        // when
        XCTAssertThrowsError(try haversack.search(where: pwQuery), "Should not find any items")
    }

    func testSearch() throws {
        // given
        strategy.mockData["classkeyslablexamm_Limitm_Lir_Data"] = [sampleKey]
        let keyQuery = KeyQuery(label: sampleDomain)

        // when
        let actual = try haversack.search(where: keyQuery)

        // then
        XCTAssertEqual(actual.count, 1)
        XCTAssertEqual(actual.first?.keySizeInBits, 2048)
        XCTAssertEqual(actual.first?.label, sampleDomain)
    }

    func testSearchAsyncNoData() throws {
        // given
        let pwQuery = InternetPasswordQuery(server: sampleDomain)
        let queryFinished = expectation(description: "search finished")

        // when
        haversack.search(where: pwQuery) { (result) in
            // then
            if case .success(let actual) = result {
                XCTFail("Should have found nothing, but we found \(actual)")
            }
            queryFinished.fulfill()
        }
        wait(for: [queryFinished], timeout: 1)
    }

    func testSearchAsync() throws {
        // given
        strategy.mockData["classkeyslablexamm_Limitm_Lir_Data"] = [sampleKey]
        let keyQuery = KeyQuery(label: sampleDomain)
        let queryFinished = expectation(description: "search finished")

        // when
        haversack.search(where: keyQuery) { (result) in
            // then
            if case .success(let actual) = result {
                XCTAssertEqual(actual.count, 1)
                XCTAssertEqual(actual.first?.keySizeInBits, 2048)
                XCTAssertEqual(actual.first?.label, self.sampleDomain)
            } else if case .failure(let error) = result {
                XCTFail("Had .failure from search(where:): \(error)")
            }
            queryFinished.fulfill()
        }
        wait(for: [queryFinished], timeout: 1)
    }

    func testSave() throws {
        // given

        // when
        let actual = try haversack.save(sampleEntity, itemSecurity: .standard, updateExisting: true)

        // then
        XCTAssertEqual(actual.server, sampleDomain)
    }

    func testSaveAsync() throws {
        // given
        let queryFinished = expectation(description: "search finished")

        // when
        haversack.save(sampleEntity, itemSecurity: .standard, updateExisting: true) { (result) in
            // then
            if case .success(let actual) = result {
                XCTAssertEqual(actual.server, self.sampleDomain)
            } else if case .failure(let error) = result {
                XCTFail("Had .failure from save(): \(error)")
            }
            queryFinished.fulfill()
        }
        wait(for: [queryFinished], timeout: 1)
    }

    func testDeleteQueryNoData() throws {
        // given
        let pwQuery = InternetPasswordQuery(server: sampleDomain)

        // when
        XCTAssertThrowsError(try haversack.delete(where: pwQuery, treatNotFoundAsSuccess: false),
                             "Should not be able to delete any items")
    }

    func testDeleteQuery() throws {
        // given
        strategy.mockData["classinetsrvrexam"] = [sampleEntity]
        let pwQuery = InternetPasswordQuery(server: sampleDomain)

        // when
        try haversack.delete(where: pwQuery)

        // then - we didn't throw an error!
    }

    func testDeleteQueryAsyncNoData() throws {
        // given
        let pwQuery = InternetPasswordQuery(server: sampleDomain)
        let queryFinished = expectation(description: "search finished")

        // when
        haversack.delete(where: pwQuery, treatNotFoundAsSuccess: false) { (result) in
            // then
            XCTAssertNotNil(result, "Should have had an error from delete(where:) but we did not")
            queryFinished.fulfill()
        }
        wait(for: [queryFinished], timeout: 1)
    }

    func testDeleteQueryAsync() throws {
        // given
        strategy.mockData["classinetsrvrexam"] = [sampleEntity]
        let pwQuery = InternetPasswordQuery(server: sampleDomain)
        let queryFinished = expectation(description: "search finished")

        // when
        haversack.delete(where: pwQuery) { (result) in
            // then
            if let error = result {
                XCTFail("Should have had no error from delete(where:) but we had \(error)")
            }
            queryFinished.fulfill()
        }
        wait(for: [queryFinished], timeout: 1)
    }

    func testDeleteEntityNoData() throws {
        // given

        // when/then
        XCTAssertThrowsError(try haversack.delete(sampleEntity, treatNotFoundAsSuccess: false),
                             "Should not be able to delete any items")
    }

    func testDeleteEntity() throws {
        // given
        strategy.mockData["classinetm_Limitm_Lisrvrexam"] = [sampleEntity]

        // when
        try haversack.delete(sampleEntity)

        // then - we didn't throw an error!
    }

    func testDeleteEntityAsyncNoData() throws {
        // given
        let queryFinished = expectation(description: "search finished")

        // when
        haversack.delete(sampleEntity, treatNotFoundAsSuccess: false) { (result) in
            // then
            XCTAssertNotNil(result, "Should have had an error from delete(where:) but we did not")
            queryFinished.fulfill()
        }
        wait(for: [queryFinished], timeout: 1)
    }

    func testDeleteEntityAsync() throws {
        // given
        strategy.mockData["classinetm_Limitm_Lisrvrexam"] = [sampleEntity]
        let queryFinished = expectation(description: "search finished")

        // when
        haversack.delete(sampleEntity) { (result) in
            // then
            if let error = result {
                XCTFail("Should have had no error from delete(where:) but we had \(error)")
            }
            queryFinished.fulfill()
        }
        wait(for: [queryFinished], timeout: 1)
    }
}
