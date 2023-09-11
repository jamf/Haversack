// swift-tools-version:5.6
// SPDX-License-Identifier: MIT
// Copyright 2023, Jamf

import PackageDescription

let package = Package(
    name: "Haversack",
    platforms: [
        .macOS(.v10_13),
        .iOS(.v12),
        .tvOS(.v12),
        .watchOS(.v5)
    ],
    products: [
        .library(name: "Haversack", targets: ["Haversack"]),
        .library(name: "HaversackCryptoKit", targets: ["HaversackCryptoKit"]),
        .library(name: "HaversackMock", targets: ["HaversackMock"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-collections", from: "1.0.4"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.2.0")
    ],
    targets: [
        .target(name: "Haversack", dependencies: [
                    .product(name: "OrderedCollections", package: "swift-collections")]),
        .target(name: "HaversackCryptoKit", dependencies: ["Haversack"]),
        .target(name: "HaversackMock", dependencies: ["Haversack"]),
        .testTarget(name: "HaversackTests", dependencies: ["HaversackMock"],
                    resources: [.copy("TestResources/")])
    ]
)
