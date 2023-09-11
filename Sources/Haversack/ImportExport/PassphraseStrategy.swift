// SPDX-License-Identifier: MIT
// Copyright 2023, Jamf

import Foundation

public enum PassphraseStrategy {
    /// Prompt the user to enter the passphrase for the item being imported or exported
    ///
    /// - prompt: The prompt to display in the secure passphrase alert panel
    /// - title: The title to display in the secure passphrase alert panel
    case promptUser(prompt: String, title: String)

    /// Use the password returned by the specified closure instead of prompting the user
    case useProvided(() -> String)
}
