// SPDX-License-Identifier: MIT
// Copyright 2023, Jamf

import os.log

struct Logs {
    static let subsystem = "com.jamf.haversack"

    static let delete = OSLog(subsystem: Logs.subsystem, category: "delete")
    static let keychainFile = OSLog(subsystem: Logs.subsystem, category: "file")
    static let save = OSLog(subsystem: Logs.subsystem, category: "save")
    static let search = OSLog(subsystem: Logs.subsystem, category: "search")
    static let keyGeneration = OSLog(subsystem: Logs.subsystem, category: "keyGeneration")
}
