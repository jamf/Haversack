# Deleting from the Keychain

Deleting items in the keychain with Haversack.

## Overview

It is possible to delete previously loaded items in an `...Entity` instance as long as the item
was returned with ``KeychainDataOptions/reference`` or ``KeychainDataOptions/attributes`` information.
When deleting based on an `...Entity` instance on macOS only the first matching keychain item will
be deleted; on iOS all matching keychain items will be deleted.

It is also possible to delete items from the keychain without loading them first by
using a `...Query` instance.

> Important: Deleting by query will delete **all** of the keychain items that match the query.

#### Deleting an Entity

```swift
// Load the entity
let pwQuery = GenericPasswordQuery(service: "Local DB Protection")
                .matching(account: "My app")
                .returning(.reference)
let haversack = Haversack()
let passwordObj = try haversack.first(where: pwQuery)

// ...use the passwordObj here...

// Delete the password from the keychain
try haversack.delete(passwordObj)
```

#### Delete by Query

```swift
let pwQuery = GenericPasswordQuery(service: "Local DB Protection")
                .matching(account: "My app")
let haversack = Haversack()
try haversack.delete(where: pwQuery)
```
