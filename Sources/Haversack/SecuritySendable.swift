// SPDX-License-Identifier: MIT
// Copyright 2026, Jamf

import Security

#if compiler(<6) // conformance for Xcode less than 16.0, @retroactive unavailable until Swift 6
extension SecCertificate: @unchecked Sendable {}
extension SecIdentity: @unchecked Sendable {}
extension SecKey: @unchecked Sendable {}
#if os(macOS)
extension SecKeychainItem: @unchecked Sendable {}
#endif
#elseif compiler(<6.2) // retroactive conformance for Xcode 16.0
extension SecCertificate: @retroactive @unchecked Sendable {}
extension SecIdentity: @retroactive @unchecked Sendable {}
extension SecKey: @retroactive @unchecked Sendable {}
#if os(macOS)
extension SecKeychainItem: @retroactive @unchecked Sendable {}
#endif
#endif
