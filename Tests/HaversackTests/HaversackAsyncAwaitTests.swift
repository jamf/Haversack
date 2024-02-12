// SPDX-License-Identifier: MIT
// Copyright 2023, Jamf

import Foundation
import Haversack
import HaversackMock
import XCTest

@available(macOS 10.15.0, iOS 13.0.0, tvOS 13.0.0, watchOS 6.0, visionOS 1.0, *)
final class HaversackAsyncAwaitTests: XCTestCase {
    var haversack: Haversack!
    var strategy: HaversackEphemeralStrategy!

    private let sampleDomain = "example.com"
    private let sampleEntity: InternetPasswordEntity = {
        let entity = InternetPasswordEntity()
        entity.server = "example.com"
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

    func testFirstAsyncNoData() async {
        // Given
        let pwQuery = InternetPasswordQuery(server: sampleDomain)

        // When
        let actual = try? await haversack.first(where: pwQuery)

        // Then
        XCTAssertNil(actual, "Should have had an error from first(where:) but didn't")
    }

    func testFirstAsync() async throws {
        // Given
        strategy.mockData["classinetm_Limitm_Lir_Datasrvrexam"] = sampleEntity
        let pwQuery = InternetPasswordQuery(server: sampleDomain)

        // When
        let actual = try await haversack.first(where: pwQuery)

        // Then
        XCTAssertEqual(actual.server, self.sampleDomain)
    }

    func testSearchAsyncNoData() async {
        // Given
        let pwQuery = InternetPasswordQuery(server: sampleDomain)

        // When
        let actual = try? await haversack.search(where: pwQuery)

        // Then
        XCTAssertNil(actual, "Should have had an error from search(where:) but didn't")
    }

    func testSearchAsync() async throws {
        // Given
        strategy.mockData["classinetm_Limitm_Lir_Refsrvrexam"] = [sampleEntity]
        let pwQuery = InternetPasswordQuery(server: sampleDomain)
                        .returning(.reference)

        // When
        let actual = try await haversack.search(where: pwQuery)

        // Then
        XCTAssertEqual(actual.count, 1)
        XCTAssertEqual(actual.first?.server, self.sampleDomain)
    }

    func testSaveAsync() async throws {
        // When
        let actual = try await haversack.save(sampleEntity, itemSecurity: .standard, updateExisting: true)

        // Then
        XCTAssertEqual(actual.server, self.sampleDomain)
    }

    func testDeleteQueryAsyncNoData() async throws {
        // Given
        let pwQuery = InternetPasswordQuery(server: sampleDomain)

        // When
        var err: Error? = nil
        do {
            try await haversack.delete(where: pwQuery, treatNotFoundAsSuccess: false)
        } catch {
            err = error
        }

        // Then
        XCTAssertNotNil(err, "Should have had an error from delete(where:treatNotFoundAsSuccess:) but didn't")
    }

    func testDeleteQueryAsync() async throws {
        // Given
        strategy.mockData["classinetsrvrexam"] = [sampleEntity]
        let pwQuery = InternetPasswordQuery(server: sampleDomain)

        // When
        var err: Error? = nil
        do {
            try await haversack.delete(where: pwQuery)
        } catch {
            err = error
        }

        if let err = err {
            XCTFail("Should have had no error from delete(where:) but we had \(err)")
        }
    }

    func testDeleteEntityAsyncNoData() async throws {
        // When
        var err: Error?
        do {
            try await haversack.delete(sampleEntity, treatNotFoundAsSuccess: false)
        } catch {
            err = error
        }

        // Then
        XCTAssertNotNil(err, "Should have had an error from delete(where:) but we did not")
    }

    func testDeleteEntityAsync() async throws {
        // Given
        strategy.mockData["classinetm_Limitm_Lisrvrexam"] = [sampleEntity]

        // When
        var err: Error? = nil
        do {
            try await haversack.delete(sampleEntity)
        } catch {
            err = error
        }

        // Then
        if let err = err {
            XCTFail("Should have had no error from delete(where:) but we had \(err)")
        }
    }
}
