# ``Haversack``

A type-safe fluent interface for the keychain on macOS, iOS/iPadOS, tvOS, visionOS, and watchOS.

## Overview

Initialize a ``Haversack/Haversack``, then use entities to save data in the keychain.
Use queries to read items from the keychain into entities; see <doc:SearchingTheKeychain>.
Items in the keychain can be deleted using a query or a previously loaded entity.
Generate new cryptographic keys (optionally in the Secure Enclave) in the keychain with a
``KeyGenerationConfig``.

### CryptoKit Support

This package includes the `HaversackCryptoKit` library which adds support for saving/restoring
CryptoKit keys in the keychain. This library must be explicitly added to a consuming project if
the project requires CryptoKit support.

### Saving Custom Types into the Keychain

Other Swift types can be stored as generic passwords by conforming to the ``GenericPasswordConvertible``
protocol. ``GenericPasswordEntity`` includes methods for converting to and from types that conform to
`GenericPasswordConvertible`.

See the `GenericPasswordConvertibleTests.swift` file for a couple of simple example types.

### Unit Testing

This package includes the `HaversackMock` library which contains a type named
`HaversackEphemeralStrategy` that implements an in-memory dictionary to mimic keychain
interactions without involving the actual keychain.  This library must be explicitly added to a
consuming project if the project requires `HaversackEphemeralStrategy`.  See <doc:UnitTesting>
for more details.

## Topics

### Top Level Types

- ``Haversack/Haversack``
- ``HaversackConfiguration``
- ``HaversackError``
- <doc:macOSKeychainFiles>
- <doc:UnitTesting>

### Keychain Queries

Keychain queries represent the search terms used for finding and deleting items stored in the keychain.

- <doc:SearchingTheKeychain>
- ``CertificateQuery``
- ``GenericPasswordQuery``
- ``IdentityQuery``
- ``InternetPasswordQuery``
- ``KeyQuery``
- <doc:QueryRelatedTypes>

### Keychain Entities

Keychain entities represent the items that are stored in the keychain.

- <doc:SavingIntoTheKeychain>
- <doc:DeletingFromTheKeychain>
- ``CertificateEntity``
- ``GenericPasswordEntity``
- ``IdentityEntity``
- ``InternetPasswordEntity``
- ``KeyEntity``
- <doc:EntityRelatedTypes>

### Creating Keys

- ``KeyGenerationConfig``

### Custom Type Support

Any type can be stored in the keychain as a generic password by conforming to this protocol.

- ``GenericPasswordConvertible``

### Item Security

- ``ItemSecurity``
- ``KeychainItemRetrievability``
- ``RetrievabilityLevel``

### Importing and Exporting Keychain Items

Certificates, keys, and identities can all be imported to and exported from the keychain.

- <doc:Importing+Exporting>
- ``KeychainImportConfig``
- ``KeychainExportConfig``
- ``KeychainPortable``
