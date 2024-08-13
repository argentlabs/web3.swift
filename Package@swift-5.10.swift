// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "web3.swift",
    platforms: [
        .iOS(SupportedPlatform.IOSVersion.v13),
        .macOS(SupportedPlatform.MacOSVersion.v11),
        .watchOS(.v7)
    ],
    products: [
        .library(name: "web3.swift", targets: ["web3"]),
        .library(name: "web3-zksync.swift", targets: ["web3-zksync"])
    ],
    dependencies: [
        .package(url: "https://github.com/attaswift/BigInt", exact: "5.3.0"),
        .package(url: "https://github.com/iwill/generic-json-swift", from: "2.0.0"),
        .package(url: "https://github.com/GigaBitcoin/secp256k1.swift.git", from: "0.6.0"),
        .package(url: "https://github.com/vapor/websocket-kit.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "web3",
            dependencies:
            [
                .target(name: "keccaktiny"),
                .target(name: "aes"),
                .target(name: "Internal_CryptoSwift_PBDKF2"),
                .product(name: "BigInt", package: "BigInt"),
                .product(name: "GenericJSON", package: "generic-json-swift"),
                .product(name: "secp256k1", package: "secp256k1.swift"),
                .product(name: "WebSocketKit", package: "websocket-kit"),
                .product(name: "Logging", package: "swift-log")
            ],
            path: "Sources/Web3Swift",
            swiftSettings: [
                //                 .concurrencyChecking
            ]
        ),
        .target(
            name: "web3-zksync",
            dependencies:
            [
                .target(name: "web3")
            ],
            path: "Sources/Web3ZKSync",
            swiftSettings: [
                //                .concurrencyChecking
            ]
        ),
        .target(
            name: "keccaktiny",
            dependencies: [],
            path: "libs/keccak-tiny",
            exclude: ["module.map"]
        ),
        .target(
            name: "aes",
            dependencies: [],
            path: "libs/aes",
            exclude: ["module.map"]
        ),
        .target(
            name: "Internal_CryptoSwift_PBDKF2",
            dependencies: [],
            path: "libs/CryptoSwift"
        ),
        .testTarget(
            name: "web3swiftTests",
            dependencies: ["web3", "web3-zksync"],
            path: "Tests/Web3SwiftTests",
            resources: [
                .copy("Resources/rlptests.json"),
                .copy("Account/cryptofights_712.json"),
                .copy("Account/ethermail_signTypedDataV4.json"),
                .copy("Account/real_word_opensea_signTypedDataV4.json"),
            ]
        )
    ]
)

extension SwiftSetting {
    /// Enable complete concurrency checking for a target in a Swift package using Swift 5.9 or Swift 5.10
    /// [Swift Concurrency Documentation](https://www.swift.org/documentation/concurrency/)
    static var concurrencyChecking: SwiftSetting {
        .enableExperimentalFeature("StrictConcurrency=complete")
    }
}
