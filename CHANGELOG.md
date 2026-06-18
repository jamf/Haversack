# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

## [2.0.0] - 2026-06-18
### Added
- Added retroactive conformance to `@unchecked Sendable` for `SecCertificate`, `SecIdentity`, `SecKey`, and `SecKeychainItem`. This is safe because Apple eventually adds this same conformance beginning in Xcode 26.
- Added convenience methods for accessing mock data values on the `HaversackEphemeralStrategy`
- Added `Sendable` conformance to all public types, protocols, and enums.
- Added support for visionOS.

### Changed
- Updated to build using Swift 6.
- Entity types (`CertificateEntity`, `GenericPasswordEntity`, `InternetPasswordEntity`, `IdentityEntity`, `KeyEntity`) converted from classes to structs.
- `PasswordBaseEntity` converted from a base class to a protocol with default implementations.
- `KeychainStorable` protocol now requires `Equatable` conformance.
- `KeychainFile` is now a `final class`.
- Query and configuration properties use `NSLock` for thread-safe access.
- Internal `CFString` dictionary keys migrated to `String` for `Sendable` compatibility.
- Completion handlers and closure properties marked `@Sendable`.

## [1.2.2] - 2026-06-18
### Changed
- 1.2.2 is equivalent to 1.1.1 due to rollback in versioning. 1.2.0 and 1.2.1 have been squashed to become version 2.0.0.

## [1.1.1] - 2024-01-05
### Changed
- System keychain is located using Security framework API.

## [1.1.0] - 2023-09-14
### Added
- Import and export capability for certificates, keys, and identities.
- Additional documentation and examples.

### Changed
- First public release.

## [1.0.0] - 2022-10-25 - internal Jamf release
### Added
- Async-await variants of all public functions that have completion handlers.

### Changed
- Queries now default to returning `.data` if not otherwise specified.
- The result of the `save()` function and it's async-await counterpart are marked as discardable.  The function returns the item that was given to it to save which is sometimes handy, but not necessary.

### Fixed
- Search queries that ask for password data for multiple password entities (generic or internet) now fail with a clear error message explaining the problem.
- On iOS, fixed the `delete` function and the `save(..., updateExisting: true)` function (that calls `delete` behind the scenes).
- When calling `save` with the `updateExisting:` parameter set to true, the code does not throw an `errSecDuplicatedItem` if the item being saved only has very basic information such as a `SecCertificate`.

## [0.0.2] - 2021-11-03 - internal Jamf release
### Added
- Cryptographic key generation with a fluent interface in `KeyGenerationConfig`.
- GitHub Actions are used to run unit tests on macOS, iOS, tvOS, and watchOS, and integration tests on macOS during Pull Requests.

## [0.0.1] - 2021-09-08 - internal Jamf release
### Added
- Initial internal Jamf release.
