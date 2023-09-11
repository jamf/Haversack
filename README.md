[![Build Status](https://github.com/jamf/Haversack/actions/workflows/swift.yml/badge.svg)](https://github.com/jamf/Haversack/actions/workflows/swift.yml)
![License](https://img.shields.io/badge/license-MIT-brightgreen.svg)

# Haversack: Swift library for keychain access

A Swift library for interacting with the Keychain on all Apple devices.  Supports macOS, iOS/iPadOS, tvOS, and watchOS.

## Goal

Simplify keychain usage for all Swift code running natively on Apple devices.

- App code should not have to touch any of the `kSec...` constants related to keychain item access.
- Keychain code should look similar/identical across all Apple operating systems.

### Features

- Supports typesafe storage and retrieval of internet passwords, generic passwords, keys/key pairs,
certificates, and identities.
- Uses a fluent interface for constructing queries to find existing keychain items.
- Provides simple keychain item access controls and security, with support for different operating system specifics.
- Is easily mockable for unit testing app code without performing actual keychain access.
- Has great unit tests and OS integration tests for confidence in this library.
- Has good documentation so all developers can easily adopt this library.

## Getting Started

### Swift Package Manager

Install with [Swift Package Manager](https://github.com/apple/swift-package-manager) by adding the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/jamf/Haversack")
],
```

## Learn more

Haversack includes documentation suitable for building with DocC.  After integrating Haversack into
a project, use Xcode's **Product > Build Documentation** menu command to compile the documentation
for local viewing in the Developer Documentation window.

## Usage

### Basic

This provides its own serial queue for thread safety and logging with
[os_log](https://developer.apple.com/documentation/os/os_log).  On macOS, this accesses
the user's login keychain.

```swift
    let myHaversack = Haversack()
```

#### Configuration

When initializing a `Haversack` instance a `HaversackConfiguration` struct can be given which
includes settings for how to access the keychain. There are settings for a serial queue, a
strategy to use, and which keychain file to use on macOS. If the default values are suitable,
no configuration is required when instantiating a `Haversack` instance.

```swift
    // Access the system keychain on macOS
    let useSystemKeychain = HaversackConfiguration(keychain: .system)
    let systemHaversack = Haversack(configuration: useSystemKeychain)
```

### Example code

Save a password for a website:

```swift
    let myHaversack = Haversack()
    let newPassword = InternetPasswordEntity()
    newPassword.protocol = .HTTPS
    newPassword.server = "test.example.com"
    newPassword.account = "mine"
    newPassword.passwordData = "top secret".data(using: .utf8)
    let savedPassword = try myHaversack.save(newPassword, itemSecurity: .standard, updateExisting: true)
```

Read the password for a website:

```swift
    let myHaversack = Haversack()
    let pwQuery = InternetPasswordQuery(server: "test.example.com")
                        .matching(account: "mine")
    let passwordObj = try myHaversack.first(where: pwQuery)

    // This is the actual password info
    _ = passwordObj.passwordData
```

Delete the password for a website without first loading it:

```swift
    let myHaversack = Haversack()
    let pwQuery = InternetPasswordQuery(server: "test.example.com")
                        .matching(account: "mine")
    try myHaversack.delete(where: pwQuery)
```

Delete the password for a website after loading it and using it:

```swift
    let myHaversack = Haversack()
    let pwQuery = InternetPasswordQuery(server: "test.example.com")
                        .matching(account: "mine")
                        .returning([.data, .reference])
    let passwordObj = try myHaversack.first(where: pwQuery)

    // Use the password here
    _ = passwordObj.passwordData

    // Then delete the password from the keychain
    try myHaversack.delete(passwordObj)
```

## Contributing

To set up for local development, make a fork of this repo, make a branch on your fork named after
the issue or workflow you are improving, checkout your branch, then open the folder in Xcode.

This repository requires verified signed commits.  You can find out more about
[signing commits on GitHub Docs](https://docs.github.com/en/authentication/managing-commit-signature-verification/signing-commits).

### Pull requests

Before submitting your pull request, please do the following:

- If you are adding new commands or features, they should include unit tests.  If you are changing functionality, update the tests or add new tests as needed.
- Verify all unit tests pass on all four supported operating systems.  There are two ways to do this:
	1. In Xcode you can switch destinations to each of the following: "My Mac", any iOS Simulator, any tvOS Simulator, and any watchOS Simulator.  Run the unit tests for each of the destinations.
	2. Four command line invocations:
		- `swift test` to verify macOS functionality.
		- `xcodebuild test -scheme Haversack-Package -destination 'platform=iOS Simulator,name=iPhone 14'` to verify iOS functionality.
		- `xcodebuild test -scheme Haversack-Package -destination 'platform=tvOS Simulator,name=Apple TV 4K (3rd generation)'` to verify tvOS functionality.
		- `xcodebuild test -scheme Haversack-Package -destination 'platform=watchOS Simulator,name=Apple Watch Series 8 (41mm)` to verify watchOS functionality.
- Run [SwiftLint](https://github.com/realm/SwiftLint) on the code.  Fix any warnings or errors that appear.
- Add a note to the CHANGELOG describing what you changed.
- If your pull request is related to an issue, add a link to the issue in the description.

## Contributors

- Kyle Hammond
- Jacob Hearst
