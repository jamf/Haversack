# Importing and Exporting Keychain Items

Importing and exporting keychain items with Haversack 

## Overview

Haversack provides two simple interfaces for importing and exporting keychain items:
- To import a keychain item, load your items into memory as `Data`, then supply that and a
``KeychainImportConfig`` to ``Haversack/Haversack/importItems(_:config:)``
- To export keychain items, retrieve them from the keychain using Haversack and then supply
the entity or entities along with a ``KeychainExportConfig`` to
``Haversack/Haversack/exportItems(_:config:)``. if the item is marked non-exportable in the
keychain, this function throws a ``HaversackError/keychainError(_:)`` with value
[errSecDataNotAvailable](https://developer.apple.com/documentation/security/errSecDataNotAvailable).

If you want to import a keychain item without saving it to a keychain, you can use the
``KeychainImportConfig/returnEntitiesWithoutSaving()`` modifier. This is incompatible with
modifiers that set keychain attributes for the imported items, such as
``KeychainImportConfig/extractable()`` or ``KeychainImportConfig/importOnlyOne()``.

### Importing entities

#### Certificates
```swift
// Retrieve the certificate as `Data`
let url = URL(fileURLWithPath: "mycertificate.cer")
let data = try Data(contentsOf: url)

// Create the configuration
let config = KeychainImportConfig<CertificateEntity>()

// Import the data
let items: [CertificateEntity] = try haversack.importItems(data, config: config)

// Do something with your newly imported certificate
```

#### Keys
```swift
// Retrieve the key as `Data`
let url = URL(fileURLWithPath: "mykey.bsafe")
let keyData = try Data(contentsOf: url)

// Create the configuration
let config = KeychainImportConfig<KeyEntity>().inputFormat(.formatBSAFE)

// Import the data
let items = try haversack.importItems(data, config: config)

// Do something with your newly imported key
```

#### Identities
```swift
// Retrieve the identity as `Data`
let url = URL(fileURLWithPath: "myidentity.p12")
let data = try Data(contentsOf: url)

// Create the configuration
let config = KeychainImportConfig<IdentityEntity>()
    .fileNameOrExtension("myidentity.p12")
    .passphraseStrategy(.useProvided({ "somesecurepassphrase" }))

// Import the data
let items: [IdentityEntity] = try haversack.importItems(data, config: config)

// Do something with your newly imported identity
```

### Exporting entities

#### Certificates
```swift
// Search for the certificate
let query = CertificateQuery(label: "My Certificate")
    .returning(.reference) // Required for export
let entity = try haversack.first(where: query)

// Make the config
let exportConfig = KeychainExportConfig(outputFormat: .formatPEMSequence)

// Export the certificate
let data = try haversack.exportItems([entity], config: exportConfig)

// Do something with your exported data
let certificate: SecCertificate = items.first?.reference
```

#### Keys
```swift
// Search for the key
let query = KeyQuery(label: "My Key")
    .matching(keyAlgorithm: .RSA)
    .returning(.reference) // Required for export

let entity = try haversack.first(where: query)

// Make the config
let exportConfig = KeychainExportConfig(outputFormat: .formatPKCS12)
    .passphraseStrategy(.useProvided({ "somesecurepassphrase" }))

// Export the key
let data = try haversack.exportItems([entity], config: exportConfig)

// Do something with your exported data
```

#### Identities
```swift
// Search for the identity
let query = IdentityQuery(label: "unit test identity")
    .returning(.reference) // Required for export
let item = try haversack.first(where: query)

// Make the config
let config = KeychainExportConfig(outputFormat: .formatPKCS12)
    .passphraseStrategy(.useProvided({ "somesecurepassphrase" }))

// Export the identity
let data = try haversack.exportItems([item], config: config)

// Do something with your exported data
```
