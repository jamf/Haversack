// SPDX-License-Identifier: MIT
// Copyright 2026, Jamf

import Foundation
import Haversack
import HaversackMock

/// An ephemeral strategy whose `save` calls throw the queued errors in order before falling back to the
/// normal ephemeral behavior.
final class FailingSaveStrategy: HaversackEphemeralStrategy, @unchecked Sendable {
    /// Errors to throw from successive calls to `save`; each call removes the first error.
    var saveErrors: [Error]

    /// The number of times `save` has been called.
    private(set) var saveCallCount = 0

    init(saveErrors: [Error]) {
        self.saveErrors = saveErrors
    }

    override func save(_ item: SecurityFrameworkQuery) throws {
        saveCallCount += 1

        if !saveErrors.isEmpty {
            throw saveErrors.removeFirst()
        }

        try super.save(item)
    }
}
