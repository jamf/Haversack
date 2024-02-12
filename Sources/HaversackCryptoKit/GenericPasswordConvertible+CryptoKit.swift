// SPDX-License-Identifier: MIT
// Copyright 2023, Jamf

import CryptoKit
import Foundation
import Haversack

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, visionOS 1.0, *)
extension Curve25519.KeyAgreement.PrivateKey: GenericPasswordConvertible {
    public static func make(fromRaw data: Data) throws -> Self {
        return try Self.init(rawRepresentation: data)
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, visionOS 1.0, *)
extension Curve25519.Signing.PrivateKey: GenericPasswordConvertible {
    public static func make(fromRaw data: Data) throws -> Self {
        return try Self.init(rawRepresentation: data)
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, visionOS 1.0, *)
extension SymmetricKey: GenericPasswordConvertible {
    public static func make(fromRaw data: Data) throws -> Self {
        return Self.init(data: data)
    }

    public var rawRepresentation: Data {
        return self.withUnsafeBytes { buffer in
            Data(buffer)
        }
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, visionOS 1.0, *)
extension SecureEnclave.P256.KeyAgreement.PrivateKey: GenericPasswordConvertible {
    public static func make(fromRaw data: Data) throws -> Self {
        return try Self.init(dataRepresentation: data)
    }

    public var rawRepresentation: Data {
        return dataRepresentation
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, visionOS 1.0, *)
extension SecureEnclave.P256.Signing.PrivateKey: GenericPasswordConvertible {
    public static func make(fromRaw data: Data) throws -> Self {
        return try Self.init(dataRepresentation: data)
    }

    public var rawRepresentation: Data {
        return dataRepresentation
    }
}
