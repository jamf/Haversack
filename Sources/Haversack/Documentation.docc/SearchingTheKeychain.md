# Searching the Keychain

Finding items within the keychain with Haversack.

## Overview

Haversack queries are used to search for keychain items.

Use the Haversack instance methods ``Haversack/Haversack/first(where:)-6ukc6`` and
``Haversack/Haversack/search(where:)-31zqu`` to load a single keychain item or multiple
keychain items matching a query. Build new queries by instantiating one of the `...Query`
types, and then use fluent function calls to narrow the search.

You can use the ``KeychainQuerying/returning(_:)-2me7p`` fluent function to decide what kind
of information the query should return. If unspecified, the default is the same as calling
`returning(.data)`. Generally, your application can gain access without prompting the user
for any keychain item (including the protected data) that your application has already added
to the keychain.

### macOS Security Prompts

Note that on macOS, running a query _may_ display an authentication prompt to the user if
the query attempts to access the data of a protected keychain item that the app does not
already have permission to use. The data is accessed by including `.data` in the call to the
`returning()` function. For example: `returning(.data)` or `returning([.data, .reference])`.

> Important: Do not store sensitive information in the attributes of a keychain item on macOS.
These attributes are viewable by all apps that have read access to that keychain. Code can query
for the `.reference`, `.attributes`, and `.persistentReference` for all items without prompting
the user.

### Search Examples

#### Internet passwords
```swift
let pwQuery = InternetPasswordQuery(server: "test.example.com")
    .matching(port: 8000)
let haversack = Haversack()
let passwordObjArray = try haversack.search(where: pwQuery)
```

#### Generic passwords
```swift
let pwQuery = GenericPasswordQuery(service: "Local DB Protection")
    .matching(account: "My app")
    .returning([.data, .attributes, .reference])
let haversack = Haversack()
let passwordObj = try haversack.first(where: pwQuery)
let secretData = passwordObj.passwordData
```

#### Cryptographic Keys
```swift
let keyQuery = KeyQuery(label: "Garage Keys")
    .matching(keyClass: .private)
    .matching(keyAlgorithm: .ellipticCurvePrimeRandom)
    .returning(.reference)
let haversack = Haversack()
let keyObj = try haversack.first(where: keyQuery)
```

#### Certificates
```swift
let certQuery = CertificateQuery(label: "ImportantCert")
    .stringMatching(options: [.caseInsensitive])
    .matching(email: "test@example.com")
    .matchingSubject(.contains, "Example")
    .matchingSubject(.startsWith, "Test")
    .matchingSubject(.endsWith, "Certificate")
    .matchingSubject(.isExactly, "Test Example Certificate")
    .matching(mustBeValidOnDate: NSDate.now)
    .trustedOnly()
    .returning(.data)
let haversack = Haversack()
let certObj = try haversack.first(where: certQuery)
```

#### Identities

An identity is the combination of a certificate plus a private key.

```swift
let identityQuery = IdentityQuery(label: "Important Identity")
    .matching(email: "test@example.com")
    .matchingSubject(.isExactly, "My Example Identity")
    .matching(mustBeValidOnDate: NSDate.now)
    .trustedOnly()
    .returning(.reference)
let haversack = Haversack()
let identityObj = try haversack.first(where: identityQuery)
```

### Synchronous or Asynchronous Queries

`.first(where:)` and `search(where:)` have both synchronous and asynchronous variants.

##### Synchronous example
```swift
let pwQuery = InternetPasswordQuery(server: "test.example.com")
    .matching(port: 8000)
let haversack = Haversack()
let passwordObjArray = try haversack.search(where: pwQuery)
```

##### Asynchronous example
```swift
// Use an async callback
let pwQuery = InternetPasswordQuery(server: "test.example.com")
    .matching(port: 8000)
let haversack = Haversack()
haversack.search(where: pwQuery, completionQueue: .main) { (result) in
    // we are on the main queue...
    if case .success(let passwordObjArray) = result {
        // ...and we have the passwords
    } else if case .failure(let error) = result {
        // ...or there was an error
    }
}

// Or use Swift async/await syntax
Task {
    do {
        let result = try await haversack.search(where: pwQuery)
        // Use your result value
    } catch {
        // Received an error
    }
}
```
