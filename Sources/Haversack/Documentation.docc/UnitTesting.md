# Unit Testing with Haversack

Haversack strategies for unit testing keychain related code.

## Overview

Calls to the Security framework are encapsulated to make testing Haversack itself **and**
consuming code easier.

Haversack makes use of the [strategy pattern](https://refactoring.guru/design-patterns/strategy)
for actual access to the keychain.  The default `HaversackStrategy` makes use of the usual
Security framework functions like `SecItemCopyMatching`, `SecItemAdd`, etc., and does system
logging of keychain activities and errors.

The `HaversackMock` library has a type named `HaversackEphemeralStrategy` that implements an
in-memory dictionary to mimic keychain interactions without involving the actual keychain. The
`HaversackEphemeralStrategy` does not make any Security framework calls or perform any system
logging. This strategy is suitable for unit tests or UI tests of application code to ensure that
no actual keychain values are needed or modified during testing.

#### Example Using HaversackEphemeralStrategy

The `HaversackEphemeralStrategy` can be set by using a ``HaversackConfiguration``:

```swift
import Haversack
import HaversackMock

let strategy = HaversackEphemeralStrategy()
let config = HaversackConfiguration(strategy: strategy)
let haversack = Haversack(configuration: config)

// Call functions on `haversack` as usual.
```

`HaversackEphemeralStrategy` has a property named `mockData` that is used to store anything saved by
``Haversack/Haversack``. The `mockData` can also be populated directly so queries can find the right
data. See the file `HaversackTests.swift` in the `Tests/HaversackTests` folder for actual usage
examples.

## Topics

### Types

- ``HaversackStrategy``
- ``SecurityFrameworkQuery``
