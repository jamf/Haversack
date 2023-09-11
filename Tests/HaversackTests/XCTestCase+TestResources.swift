// SPDX-License-Identifier: MIT
// Copyright 2023, Jamf

import Foundation
import XCTest

extension XCTestCase {
    /// When loading test data files use this method.  This works as long as all the test files are in the `TestResources`folder of the tests directory.
    /// - Parameters:
    ///   - named: The full name of the file to load.  For example `TestData.xml`
    ///   - relativeToPath: Filled in automatically by the compiler to find the test file on disk.
    /// - Returns: The URL of the file within the test bundle; or nil if the test file cannot be found.
    func getURLForTestResource(named: String, relativeToPath: StaticString = #file) -> URL {
        let path = URL(fileURLWithPath: "\(relativeToPath)")
        let testURL = path.deletingLastPathComponent().appendingPathComponent("TestResources").appendingPathComponent(named)
        // Causes a wait of 0.002 seconds; why this is important I don't know.
        // The data file doesn't always load unless we wait.  Strange filesystem voodoo?
        usleep(2000)
        return testURL
    }
}
