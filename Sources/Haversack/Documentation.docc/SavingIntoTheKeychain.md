# Saving into the Keychain

Saving items into the keychain with Haversack.

## Overview

Haversack entities (types ending with `...Entity`) are used to store items in the keychain.

Use one of the following Haversack instance methods to save a single keychain item.
- Synchronous: ``Haversack/Haversack/save(_:itemSecurity:updateExisting:)-5zo28``
- Using async-await: ``Haversack/Haversack/save(_:itemSecurity:updateExisting:)-5ewn6``
- Asynchronous with callback
``Haversack/Haversack/save(_:itemSecurity:updateExisting:completionQueue:completion:)``

> Important: Do not store sensitive information in the attributes of a keychain item on macOS. These
attributes are viewable by all apps that have read access to that keychain. Code can query for
the `.reference`, `.attributes`, and `.persistentReference` for all items without prompting the user.

#### Item Security

Use ``ItemSecurity`` to specify which keychain group or app group for the item, what state the device
must be in to retrieve the item, and whether the item will move to other devices via
[iCloud Keychain](https://support.apple.com/en-us/HT204085).

Haversack encapsulates the `kSecAttrAccessible...` values for keychain items into the
``RetrievabilityLevel`` enum. The name was chosen to express when items can be retrieved for use,
and to stay well away from the accessibility APIs that are used for user experience accommodations.

### Saving Entities

#### Internet and generic passwords

Create an instance of either ``InternetPasswordEntity`` or ``GenericPasswordEntity``, then
populate it with some data. Most metadata fields are optional but be sure to include enough
metadata so that you can uniquely query for the item later.

``PasswordBaseEntity/passwordData`` is where the secret password data should be stored.

```swift
let newPassword = InternetPasswordEntity()
newPassword.protocol = .HTTPS
newPassword.server = "test.example.com"
newPassword.account = "mine"
newPassword.passwordData = "top secret".data(using: .utf8)
let haversack = Haversack()
let savedPassword = try haversack.save(newPassword, itemSecurity: .standard, updateExisting: true)
```

#### Certificates

Create an instance of ``CertificateEntity`` from a `SecCertificate` that was created elsewhere.

```swift
let certData: Data = ... // populate certData from somewhere; a DER-encoded file, a network response, etc
if let certRef = SecCertificateCreateWithData(nil, certData as CFData) {
    let newCertificate = CertificateEntity(from: certRef)
    let haversack = Haversack()
    let savedCert = try haversack.save(newCertificate, itemSecurity: .standard, updateExisting: false)
}
```

### Generating Keys

Creating new asymmetric key pairs can be fairly complex, but Haversack simplifies the process
with the ``KeyGenerationConfig`` type. To generate a key, first use
``KeyGenerationConfig/init(algorithm:keySize:)`` for standard keys, and
``KeyGenerationConfig/init(secureEnclaveRetrievableWhen:flags:)`` for keys
that should be generated in the Secure Enclave. Use the fluent methods of ``KeyGenerationConfig``
to build up the key generation with labels, tags, and additional metadata as needed. Then, pass
that configuration to the ``Haversack/Haversack/generateKey(fromConfig:itemSecurity:)-1r4ki``
method (which also has async variants).

```swift
let keyInfo = KeyGenerationConfig(algorithm: .RSA, keySize: 4096)
                    .labeled("My Simple Key")
let haversack = Haversack()
let newKey = try haversack.generateKey(fromConfig: keyInfo, itemSecurity: .standard)

let seKeyInfo = try KeyGenerationConfig(secureEnclaveRetrievableWhen: .unlockedThisDeviceOnly, flags: .biometryAny)
                    .labeled("My Secure Enclave Key")
let newSEKey = try haversack.generateKey(fromConfig: seKeyInfo, itemSecurity: ItemSecurity())    
```
