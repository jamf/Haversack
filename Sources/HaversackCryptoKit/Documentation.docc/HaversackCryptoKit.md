# ``HaversackCryptoKit``

Supporting CryptoKit types within Haversack.

## Overview

Several [CryptoKit](https://developer.apple.com/documentation/cryptokit/) types can be stored
and loaded from the keychain using Haversack. Where possible, the CryptoKit keys are stored as
`SecKey` instances using `KeyEntity`. If `SecKey` compatibility is impossible, such as with
`Curve25519` keys, the CryptoKit keys are stored as generic passwords as
[recommended by Apple](https://developer.apple.com/documentation/cryptokit/storing_cryptokit_keys_in_the_keychain)
using `GenericPasswordEntity`.

| CryptoKit type | Haversack type |
| --- | --- |
| [Curve25519.KeyAgreement.PrivateKey](https://developer.apple.com/documentation/cryptokit/curve25519/keyagreement/privatekey) | GenericPasswordEntity |
| [Curve25519.Signing.PrivateKey](https://developer.apple.com/documentation/cryptokit/curve25519/signing/privatekey) | GenericPasswordEntity |
| [P256.KeyAgreement.PrivateKey](https://developer.apple.com/documentation/cryptokit/p256/keyagreement/privatekey) | KeyEntity |
| [P256.Signing.PrivateKey](https://developer.apple.com/documentation/cryptokit/p256/signing/privatekey) | KeyEntity |
| [P384.KeyAgreement.PrivateKey](https://developer.apple.com/documentation/cryptokit/p384/keyagreement/privatekey) | KeyEntity |
| [P384.Signing.PrivateKey](https://developer.apple.com/documentation/cryptokit/p384/signing/privatekey) | KeyEntity |
| [P521.KeyAgreement.PrivateKey](https://developer.apple.com/documentation/cryptokit/p521/keyagreement/privatekey) | KeyEntity |
| [P521.Signing.PrivateKey](https://developer.apple.com/documentation/cryptokit/p521/signing/privatekey) | KeyEntity |
| [SecureEnclave.P256.KeyAgreement.PrivateKey](https://developer.apple.com/documentation/cryptokit/secureenclave/p256/keyagreement/privatekey) | GenericPasswordEntity |
| [SecureEnclave.P256.Signing.PrivateKey](https://developer.apple.com/documentation/cryptokit/secureenclave/p256/signing/privatekey) | GenericPasswordEntity |
| [SymmetricKey](https://developer.apple.com/documentation/cryptokit/symmetrickey) | GenericPasswordEntity |

### Example with KeyEntity supported type

Save a CryptoKit key into the keychain:

```swift
    let haversack = Haversack()
    let key = P256.Signing.PrivateKey()
    let keyEntity = try KeyEntity(key)
    keyEntity.label = "example label"
    try haversack.save(keyEntity, itemSecurity: .standard, updateExisting: true)
```

Read that same CryptoKit key from the keychain:

```swift
    let haversack = Haversack()
    let query = KeyQuery(label: "example label")
    let keyEntity = try haversack.first(where: query)
    let key = try keyEntity.originalEntity() as P256.Signing.PrivateKey
    // Alternative syntax that can be used
    let sameKey: P256.Signing.PrivateKey = try keyEntity.originalEntity()
```

### Example with GenericPasswordEntity supported type

Save a CryptoKit key into the keychain:

```swift
    let haversack = Haversack()
    let key = SymmetricKey(size: .bits256)
    let keyEntity = GenericPasswordEntity(key)
    keyEntity.service = "example service"
    try haversack.save(keyEntity, itemSecurity: .standard, updateExisting: true)
```

Read that same CryptoKit key from the keychain:

```swift
    let haversack = Haversack()
    let query = GenericPasswordQuery(service: "example service")
    let keyEntity = try haversack.first(where: query)
    let key = try keyEntity.originalEntity() as SymmetricKey
    // Alternative syntax that can be used
    let sameKey: SymmetricKey = try keyEntity.originalEntity()
```

## Topics

### Protocol

- ``SecKeyConvertible``
