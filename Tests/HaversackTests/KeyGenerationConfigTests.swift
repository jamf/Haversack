// SPDX-License-Identifier: MIT
// Copyright 2023, Jamf

import XCTest
import Haversack

final class KeyGenerationConfigTests: XCTestCase {
    func testBasicKey() throws {
        // given
        let keyInfo = KeyGenerationConfig(algorithm: .RSA, keySize: 4096)

        // when
        let actual = keyInfo.query

        // then
        XCTAssertEqual(actual.count, 5)
        XCTAssertEqual(actual[kSecAttrKeyType as String] as! CFString, kSecAttrKeyTypeRSA)
        XCTAssertEqual(actual[kSecAttrKeySizeInBits as String] as! Int, 4096)
        XCTAssertEqual(actual[kSecAttrIsExtractable as String] as! Bool, false)
        let pubInfo = try XCTUnwrap(actual[kSecPublicKeyAttrs as String] as? SecurityFrameworkQuery)
        XCTAssertEqual(pubInfo.count, 1)
        XCTAssertEqual(pubInfo[kSecAttrIsPermanent as String] as! Bool, false)
        let privInfo = try XCTUnwrap(actual[kSecPrivateKeyAttrs as String] as? SecurityFrameworkQuery)
        XCTAssertEqual(privInfo.count, 1)
        XCTAssertEqual(privInfo[kSecAttrIsPermanent as String] as! Bool, true)
    }

    func testEmptyLabelsAndTagsAreNotAdded() throws {
        // given
        let keyInfo = KeyGenerationConfig(algorithm: .RSA, keySize: 4096)

        // when
        let unchangedKey = keyInfo.labeled("")
            .tagged(Data())
            .privateKey(labeled: "")
            .privateKey(tagged: Data())
            .publicKey(labeled: "")
            .publicKey(tagged: Data())

        // then
        let actual = unchangedKey.query
        XCTAssertEqual(actual.count, 5)
        XCTAssertEqual(actual[kSecAttrKeyType as String] as! CFString, kSecAttrKeyTypeRSA)
        XCTAssertEqual(actual[kSecAttrKeySizeInBits as String] as! Int, 4096)
        XCTAssertEqual(actual[kSecAttrIsExtractable as String] as! Bool, false)
        let pubInfo = try XCTUnwrap(actual[kSecPublicKeyAttrs as String] as? SecurityFrameworkQuery)
        XCTAssertEqual(pubInfo.count, 1)
        XCTAssertEqual(pubInfo[kSecAttrIsPermanent as String] as! Bool, false)
        let privInfo = try XCTUnwrap(actual[kSecPrivateKeyAttrs as String] as? SecurityFrameworkQuery)
        XCTAssertEqual(privInfo.count, 1)
        XCTAssertEqual(privInfo[kSecAttrIsPermanent as String] as! Bool, true)
    }

    func testKeyCanBeLabeledAndTagged() throws {
        // given
        let keyInfo = KeyGenerationConfig(algorithm: .RSA, keySize: 4096)

        // when
        let updatedKey = keyInfo.labeled("Test Key").tagged(try XCTUnwrap("some tag".data(using: .utf8)))

        // then
        let actual = updatedKey.query
        XCTAssertEqual(actual.count, 7)
        XCTAssertEqual(actual[kSecAttrKeyType as String] as! CFString, kSecAttrKeyTypeRSA)
        XCTAssertEqual(actual[kSecAttrKeySizeInBits as String] as! Int, 4096)
        XCTAssertEqual(actual[kSecAttrIsExtractable as String] as! Bool, false)
        XCTAssertEqual(actual[kSecAttrLabel as String] as! String, "Test Key")
        XCTAssertEqual(actual[kSecAttrApplicationTag as String] as? Data, "some tag".data(using: .utf8))
        let pubInfo = try XCTUnwrap(actual[kSecPublicKeyAttrs as String] as? SecurityFrameworkQuery)
        XCTAssertEqual(pubInfo.count, 1)
        XCTAssertEqual(pubInfo[kSecAttrIsPermanent as String] as! Bool, false)
        let privInfo = try XCTUnwrap(actual[kSecPrivateKeyAttrs as String] as? SecurityFrameworkQuery)
        XCTAssertEqual(privInfo.count, 1)
        XCTAssertEqual(privInfo[kSecAttrIsPermanent as String] as! Bool, true)
    }

    func testPrivateKeyCanBeLabeledAndTagged() throws {
        // given
        let keyInfo = KeyGenerationConfig(algorithm: .RSA, keySize: 4096)

        // when
        let updatedKey = keyInfo.privateKey(labeled: "Priv Key")
            .privateKey(tagged: try XCTUnwrap("a tag".data(using: .utf8)))

        // then
        let actual = updatedKey.query
        XCTAssertEqual(actual.count, 5)
        XCTAssertEqual(actual[kSecAttrKeyType as String] as! CFString, kSecAttrKeyTypeRSA)
        XCTAssertEqual(actual[kSecAttrKeySizeInBits as String] as! Int, 4096)
        XCTAssertEqual(actual[kSecAttrIsExtractable as String] as! Bool, false)
        let pubInfo = try XCTUnwrap(actual[kSecPublicKeyAttrs as String] as? SecurityFrameworkQuery)
        XCTAssertEqual(pubInfo.count, 1)
        XCTAssertEqual(pubInfo[kSecAttrIsPermanent as String] as! Bool, false)
        let privInfo = try XCTUnwrap(actual[kSecPrivateKeyAttrs as String] as? SecurityFrameworkQuery)
        XCTAssertEqual(privInfo.count, 3)
        XCTAssertEqual(privInfo[kSecAttrIsPermanent as String] as! Bool, true)
        XCTAssertEqual(privInfo[kSecAttrLabel as String] as! String, "Priv Key")
        XCTAssertEqual(privInfo[kSecAttrApplicationTag as String] as? Data, "a tag".data(using: .utf8))
    }

    func testPublicKeyCanBeLabeledAndTagged() throws {
        // given
        let keyInfo = KeyGenerationConfig(algorithm: .RSA, keySize: 4096)

        // when
        let updatedKey = keyInfo.publicKey(labeled: "Priv Key")
            .publicKey(tagged: try XCTUnwrap("a tag".data(using: .utf8)))

        // then
        let actual = updatedKey.query
        XCTAssertEqual(actual.count, 5)
        XCTAssertEqual(actual[kSecAttrKeyType as String] as! CFString, kSecAttrKeyTypeRSA)
        XCTAssertEqual(actual[kSecAttrKeySizeInBits as String] as! Int, 4096)
        XCTAssertEqual(actual[kSecAttrIsExtractable as String] as! Bool, false)
        let pubInfo = try XCTUnwrap(actual[kSecPublicKeyAttrs as String] as? SecurityFrameworkQuery)
        XCTAssertEqual(pubInfo.count, 3)
        XCTAssertEqual(pubInfo[kSecAttrIsPermanent as String] as! Bool, false)
        XCTAssertEqual(pubInfo[kSecAttrLabel as String] as! String, "Priv Key")
        XCTAssertEqual(pubInfo[kSecAttrApplicationTag as String] as? Data, "a tag".data(using: .utf8))
        let privInfo = try XCTUnwrap(actual[kSecPrivateKeyAttrs as String] as? SecurityFrameworkQuery)
        XCTAssertEqual(privInfo.count, 1)
        XCTAssertEqual(privInfo[kSecAttrIsPermanent as String] as! Bool, true)
    }

    func testPrivateKeyCanHaveUsage() throws {
        // given
        let keyInfo = KeyGenerationConfig(algorithm: .RSA, keySize: 4096)

        // when - only want to sign and decrypt things
        let updatedKey = keyInfo.privateKey(usage: [.canSign, .canDecrypt])

        // then
        let actual = updatedKey.query
        XCTAssertEqual(actual.count, 5)
        XCTAssertEqual(actual[kSecAttrKeyType as String] as! CFString, kSecAttrKeyTypeRSA)
        XCTAssertEqual(actual[kSecAttrKeySizeInBits as String] as! Int, 4096)
        XCTAssertEqual(actual[kSecAttrIsExtractable as String] as! Bool, false)
        let pubInfo = try XCTUnwrap(actual[kSecPublicKeyAttrs as String] as? SecurityFrameworkQuery)
        XCTAssertEqual(pubInfo.count, 1)
        XCTAssertEqual(pubInfo[kSecAttrIsPermanent as String] as! Bool, false)
        let privInfo = try XCTUnwrap(actual[kSecPrivateKeyAttrs as String] as? SecurityFrameworkQuery)
        XCTAssertEqual(privInfo.count, 5)
        XCTAssertEqual(privInfo[kSecAttrIsPermanent as String] as! Bool, true)
        XCTAssertEqual(privInfo[kSecAttrCanDecrypt as String] as! Bool, true)
        XCTAssertEqual(privInfo[kSecAttrCanSign as String] as! Bool, true)
        XCTAssertEqual(privInfo[kSecAttrCanDerive as String] as! Bool, false, "Default usage is disabled")
        XCTAssertEqual(privInfo[kSecAttrCanUnwrap as String] as! Bool, false, "Default usage is disabled")
    }

    func testPublicKeyCanHaveUsage() throws {
        // given
        let keyInfo = KeyGenerationConfig(algorithm: .RSA, keySize: 4096)

        // when - only want to verify and encrypt things
        let updatedKey = keyInfo.publicKey(usage: [.canVerify, .canEncrypt])

        // then
        let actual = updatedKey.query
        XCTAssertEqual(actual.count, 5)
        XCTAssertEqual(actual[kSecAttrKeyType as String] as! CFString, kSecAttrKeyTypeRSA)
        XCTAssertEqual(actual[kSecAttrKeySizeInBits as String] as! Int, 4096)
        XCTAssertEqual(actual[kSecAttrIsExtractable as String] as! Bool, false)
        let pubInfo = try XCTUnwrap(actual[kSecPublicKeyAttrs as String] as? SecurityFrameworkQuery)
        XCTAssertEqual(pubInfo.count, 4)
        XCTAssertEqual(pubInfo[kSecAttrIsPermanent as String] as! Bool, false)
        XCTAssertEqual(pubInfo[kSecAttrCanEncrypt as String] as! Bool, true)
        XCTAssertEqual(pubInfo[kSecAttrCanVerify as String] as! Bool, true)
        XCTAssertEqual(pubInfo[kSecAttrCanDerive as String] as! Bool, false, "Default usage is disabled")
        let privInfo = try XCTUnwrap(actual[kSecPrivateKeyAttrs as String] as? SecurityFrameworkQuery)
        XCTAssertEqual(privInfo.count, 1)
        XCTAssertEqual(privInfo[kSecAttrIsPermanent as String] as! Bool, true)
    }

    func testSecureEnclaveKey() throws {
        // given
        let keyInfo = try KeyGenerationConfig(secureEnclaveRetrievableWhen: .unlockedThisDeviceOnly, flags: .biometryAny)

        // when
        let actual = keyInfo.query

        // then
        XCTAssertEqual(actual.count, 6)
        XCTAssertEqual(actual[kSecAttrTokenID as String] as! CFString, kSecAttrTokenIDSecureEnclave)
        XCTAssertEqual(actual[kSecAttrKeyType as String] as! CFString, kSecAttrKeyTypeECSECPrimeRandom)
        XCTAssertEqual(actual[kSecAttrKeySizeInBits as String] as! Int, 256)
        XCTAssertEqual(actual[kSecAttrIsExtractable as String] as! Bool, false)
        let pubInfo = try XCTUnwrap(actual[kSecPublicKeyAttrs as String] as? SecurityFrameworkQuery)
        XCTAssertEqual(pubInfo.count, 1)
        XCTAssertEqual(pubInfo[kSecAttrIsPermanent as String] as! Bool, false)
        let privInfo = try XCTUnwrap(actual[kSecPrivateKeyAttrs as String] as? SecurityFrameworkQuery)
        XCTAssertEqual(privInfo.count, 2)
        XCTAssertEqual(privInfo[kSecAttrIsPermanent as String] as! Bool, true)
        XCTAssertNotNil(privInfo[kSecAttrAccessControl as String])
    }

    func testSecureEnclaveKeyCannotSynchronize() throws {
        // given/when
        XCTAssertThrowsError(try KeyGenerationConfig(secureEnclaveRetrievableWhen: .unlocked),
                             "Secure Enclave keys should not allow synchronization") { error in
            // then
            guard let haversackError = error as? HaversackError else {
                XCTFail("Should throw a HaversackError but threw \(error)")
                return
            }
            XCTAssertEqual(haversackError,
                           .notPossible("Secure Enclave keys cannot be marked as synchronizable to iCloud Keychain and backups"))
        }

        XCTAssertThrowsError(try KeyGenerationConfig(secureEnclaveRetrievableWhen: .afterFirstUnlock),
                             "Secure Enclave keys should not allow synchronization") { error in
            // then
            guard let haversackError = error as? HaversackError else {
                XCTFail("Should throw a HaversackError but threw \(error)")
                return
            }
            XCTAssertEqual(haversackError,
                           .notPossible("Secure Enclave keys cannot be marked as synchronizable to iCloud Keychain and backups"))
        }
    }

    func testExtractionNotAllowedForSecureEnclaveKeys() throws {
        // given
        let keyInfo = try KeyGenerationConfig(secureEnclaveRetrievableWhen: .unlockedThisDeviceOnly)

        // when
        XCTAssertThrowsError(try keyInfo.extractionAllowed(true),
                            "Top level extraction should not be allowed for Secure Enclave key") { error in
            // then
            guard let haversackError = error as? HaversackError,
                  haversackError == .notPossible("Secure Enclave keys cannot be marked as extractable") else {
                XCTFail("Should throw a HaversackError but threw \(error)")
                return
            }
        }

        // when
        XCTAssertThrowsError(try keyInfo.publicKey(extractionAllowed: true),
                            "Public key extraction should not be allowed for Secure Enclave key") { error in
            // then
            guard let haversackError = error as? HaversackError,
                  haversackError == .notPossible("Secure Enclave keys cannot be marked as extractable") else {
                XCTFail("Should throw a HaversackError but threw \(error)")
                return
            }
        }
    }

    func testExtractionIsAllowedForNormalKeys() throws {
        // given
        let keyInfo = KeyGenerationConfig(algorithm: .RSA, keySize: 4096)

        // when
        let extractableKey = try keyInfo.extractionAllowed(true)
            .publicKey(extractionAllowed: true)

        // then
        let actual = extractableKey.query
        XCTAssertEqual(actual.count, 5)
        XCTAssertEqual(actual[kSecAttrKeyType as String] as! CFString, kSecAttrKeyTypeRSA)
        XCTAssertEqual(actual[kSecAttrKeySizeInBits as String] as! Int, 4096)
        XCTAssertEqual(actual[kSecAttrIsExtractable as String] as! Bool, true)
        let pubInfo = try XCTUnwrap(actual[kSecPublicKeyAttrs as String] as? SecurityFrameworkQuery)
        XCTAssertEqual(pubInfo.count, 2)
        XCTAssertEqual(pubInfo[kSecAttrIsPermanent as String] as! Bool, false)
        XCTAssertEqual(pubInfo[kSecAttrIsExtractable as String] as! Bool, true)
        let privInfo = try XCTUnwrap(actual[kSecPrivateKeyAttrs as String] as? SecurityFrameworkQuery)
        XCTAssertEqual(privInfo.count, 1)
        XCTAssertEqual(privInfo[kSecAttrIsPermanent as String] as! Bool, true)
    }

    func testNormalPrivateKeysCanBeMadeEphemeral() throws {
        // given
        let keyInfo = KeyGenerationConfig(algorithm: .ellipticCurvePrimeRandom, keySize: 128)

        // when
        let ephemeralKey = try keyInfo.privateKey(shouldBePermanent: false)

        // then
        let actual = ephemeralKey.query
        XCTAssertEqual(actual.count, 5)
        XCTAssertEqual(actual[kSecAttrKeyType as String] as! CFString, kSecAttrKeyTypeECSECPrimeRandom)
        XCTAssertEqual(actual[kSecAttrKeySizeInBits as String] as! Int, 128)
        XCTAssertEqual(actual[kSecAttrIsExtractable as String] as! Bool, false)
        let pubInfo = try XCTUnwrap(actual[kSecPublicKeyAttrs as String] as? SecurityFrameworkQuery)
        XCTAssertEqual(pubInfo.count, 1)
        XCTAssertEqual(pubInfo[kSecAttrIsPermanent as String] as! Bool, false)
        let privInfo = try XCTUnwrap(actual[kSecPrivateKeyAttrs as String] as? SecurityFrameworkQuery)
        XCTAssertEqual(privInfo.count, 1)
        XCTAssertEqual(privInfo[kSecAttrIsPermanent as String] as! Bool, false)
    }

    func testSecureEnclaveKeysCannotBeMadeEphemeral() throws {
        // given
        let keyInfo = try KeyGenerationConfig(secureEnclaveRetrievableWhen: .unlockedThisDeviceOnly)

        // when
        XCTAssertThrowsError(try keyInfo.privateKey(shouldBePermanent: false),
                            "Private key cannot be ephemeral for Secure Enclave key") { error in
            // then
            guard let haversackError = error as? HaversackError else {
                XCTFail("Should throw a HaversackError but threw \(error)")
                return
            }

            XCTAssertEqual(haversackError, .notPossible("Secure Enclave keys must be permanent"))
        }
    }

    func testPublicKeysCanBeMadePermanent() throws {
        // given
        let keyInfo = KeyGenerationConfig(algorithm: .ellipticCurvePrimeRandom, keySize: 128)

        // when
        let permanentKey = keyInfo.publicKey(shouldBePermanent: true)

        // then
        let actual = permanentKey.query
        XCTAssertEqual(actual.count, 5)
        XCTAssertEqual(actual[kSecAttrKeyType as String] as! CFString, kSecAttrKeyTypeECSECPrimeRandom)
        XCTAssertEqual(actual[kSecAttrKeySizeInBits as String] as! Int, 128)
        XCTAssertEqual(actual[kSecAttrIsExtractable as String] as! Bool, false)
        let pubInfo = try XCTUnwrap(actual[kSecPublicKeyAttrs as String] as? SecurityFrameworkQuery)
        XCTAssertEqual(pubInfo.count, 1)
        XCTAssertEqual(pubInfo[kSecAttrIsPermanent as String] as! Bool, true)
        let privInfo = try XCTUnwrap(actual[kSecPrivateKeyAttrs as String] as? SecurityFrameworkQuery)
        XCTAssertEqual(privInfo.count, 1)
        XCTAssertEqual(privInfo[kSecAttrIsPermanent as String] as! Bool, true)
    }
}
