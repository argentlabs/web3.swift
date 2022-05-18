// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "web3.swift",
    platforms: [
        .iOS(SupportedPlatform.IOSVersion.v13),
        .macOS(SupportedPlatform.MacOSVersion.v11)
    ],
    products: [
        .library(name: "web3.swift", targets: ["web3"]),
    ],
    dependencies: [
        .package(name: "BigInt", url: "https://github.com/attaswift/BigInt", from: "5.0.0"),
        .package(name: "GenericJSON", url: "https://github.com/zoul/generic-json-swift", from: "2.0.0"),
        .package(name: "secp256k1", url: "https://github.com/Boilertalk/secp256k1.swift", from: "0.1.0")
    ],
    targets: [
        .target(name: "web3",
                dependencies:
                    [.target(name: "keccaktiny"),
                     .target(name: "aes"),
                     .target(name: "Internal_CryptoSwift_PBDKF2"),
                     "BigInt",
                     "GenericJSON",
                     "secp256k1"],
                path: "web3swift/src"),
        .target(name: "keccaktiny",
                dependencies: [],
                path: "web3swift/lib/keccak-tiny",
                exclude: ["module.map"]),
        .target(name: "aes",
                dependencies: [],
                path: "web3swift/lib/aes",
                exclude: ["module.map"]),
        .target(name: "Internal_CryptoSwift_PBDKF2",
                dependencies: [],
                path: "web3swift/lib/CryptoSwift"),
        .testTarget(name: "web3swiftTests",
                    dependencies: ["web3"],
                    path: "web3sTests",
                    resources: [
                        .copy("Resources/rlptests.json"),
                        .copy("Account/cryptofights_712.json")
                    ]),
    ]
)
