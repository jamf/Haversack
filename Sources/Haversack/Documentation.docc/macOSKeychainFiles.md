# macOS Keychain Files

Work with different keychain files on macOS.

## Overview

On macOS the default ``HaversackConfiguration`` uses the user's login keychain.  Other keychain files
are supported on macOS at least through macOS 14. Apple deprecated this functionality in macOS 10.10.
Eventually Apple may remove this functionality from macOS completely at which time Haversack will
mark these functions with the correct availablity tags.

> Important: This functionality is available on macOS only. It is not officially deprecated in Haversack
yet, but it is deprecated in macOS 10.10 and higher.

## Using Another Keychain File

To create or access any other keychain, you must specify a full path to the keychain file and a
password provider block or function.  When creating or unlocking a custom keychain file, the password
provider will be called in order to provide the plain text password of the custom keychain.

Storing a block or function for the password provider reduces the amount of time that the plain text
password must reside in RAM. The password provider will return a `String`, Haversack will make use of
that `String`, and then it is freed and removed from RAM.

```swift
let keychainFile = KeychainFile(at: customFilePath) { _ in
    "the password string"
}
let customFileConfig = HaversackConfiguration(keychain: keychainFile)
let customFileHaversack = Haversack(configuration: customFileConfig)
```

### System Keychains

A couple of other interesting keychains exist on macOS, the system keychain and the root certificates
keychain. Both are easily accessible using ``KeychainFile/system`` and
``KeychainFile/systemRootCertificates``.

> Important: Processes must run as root in order to add, update, or delete anything in either
of these keychains.

```swift
let systemKeychainConfig = HaversackConfiguration(keychain: .system)
let systemHaversack = Haversack(configuration: systemKeychainConfig)

let rootCertsConfig = HaversackConfiguration(keychain: .systemRootCertificates)
let rootCertsHaversack = Haversack(configuration: rootCertsConfig)
```

## Topics

### Configuration

- ``KeychainFile``
- ``FilePath``
- ``KeychainPasswordProvider``
