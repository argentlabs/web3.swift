// swift-tools-version:5.3
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
        .package(name: "BigInt", url: "https://github.com/attaswift/BigInt", from: "5.3.0"),
        .package(name: "GenericJSON", url: "https://github.com/iwill/generic-json-swift", .upToNextMajor(from: "2.0.0")),
        .package(url: "https://github.com/GigaBitcoin/secp256k1.swift.git", .upToNextMajor(from: "0.6.0")),
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
                    "BigInt",
                    "GenericJSON",
                    .product(name: "secp256k1", package: "secp256k1.swift"),
                    .product(name: "WebSocketKit", package: "websocket-kit"),
                    .product(name: "Logging", package: "swift-log")
                ],
            path: "web3swift/src",
            exclude: ["ZKSync"]
        ),
         .target(
            name: "web3-zksync",
            dependencies:
                [
                    .target(name: "web3")
                ],
            path: "web3swift/src/ZKSync"
        ),
        .target(
            name: "keccaktiny",
            dependencies: [],
            path: "web3swift/lib/keccak-tiny",
            exclude: ["module.map"]
        ),
        .target(
            name: "aes",
            dependencies: [],
            path: "web3swift/lib/aes",
            exclude: ["module.map"]
        ),
        .target(
            name: "Internal_CryptoSwift_PBDKF2",
            dependencies: [],
            path: "web3swift/lib/CryptoSwift"
        ),
        .testTarget(
            name: "web3swiftTests",
            dependencies: ["web3", "web3-zksync"],
            path: "web3sTests",
            resources: [
                .copy("Resources/rlptests.json"),
                .copy("Account/cryptofights_712.json"),
                .copy("Account/ethermail_signTypedDataV4.json"),
                .copy("Account/real_word_opensea_signTypedDataV4.json"),
            ]
        )
    ]
)
