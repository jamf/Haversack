# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
