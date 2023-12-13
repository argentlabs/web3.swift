![web3.swift: Ethereum API for Swift](https://raw.github.com/argentlabs/web3.swift/master/web3swift.png)

[![Swift](https://github.com/argentlabs/web3.swift/actions/workflows/swift.yml/badge.svg?branch=develop)](https://github.com/argentlabs/web3.swift/actions/workflows/swift.yml)

## Installation

### Swift Package Manager

Use Xcode to add to the project (**File -> Swift Packages**) or add this to your `Package.swift` file:
```swift
.package(url: "https://github.com/argentlabs/web3.swift", from: "1.1.0")
```
### CocoaPods

Add web3.swift to your `Podfile`:

```ruby
pod 'web3.swift'
```

Then run the following command:

```bash
$ pod install
```

## Usage

### Getting Started

Create an instance of `EthereumAccount`  with a `EthereumKeyStorage` provider. This provides a wrapper around your key for web3.swift to use. **NOTE We recommend you implement your own KeyStorage provider, instead of relying on the provided `EthereumKeyLocalStorage` class. This is provided as an example for conformity to the `EthereumSingleKeyStorageProtocol`.**

```swift
import web3

// This is just an example. EthereumKeyLocalStorage should not be used in production code
let keyStorage = EthereumKeyLocalStorage()
let account = try? EthereumAccount.create(replacing: keyStorage, keystorePassword: "MY_PASSWORD")
```

Create an instance of `EthereumHttpClient` or `EthereumWebSocketClient`. This will then provide you access to a set of functions for interacting with the Blockchain.

`EthereumHttpClient`
```swift
guard let clientUrl = URL(string: "https://an-infura-or-similar-url.com/123") else { return }
let client = EthereumHttpClient(url: clientUrl)
```

OR

`EthereumWebSocketClient`
```swift
guard let clientUrl = URL(string: "wss://goerli.infura.io/ws/v3//123") else { return }
let client = EthereumWebSocketClient(url: clientUrl)
```

You can then interact with the client methods, such as to get the current gas price:

```swift
client.eth_gasPrice { (error, currentPrice) in
    print("The current gas price is \(currentPrice)")
}
```
If using `async/await` you can `await` on the result
```swift
let gasPrice = try await client.eth_gasPrice()
```

### Smart contracts: Static types

Given a smart contract function ABI like ERC20 `transfer`:
```javascript
function transfer(address recipient, uint256 amount) public returns (bool)
```

then you can define an `ABIFunction` with corresponding encodable Swift types like so:

```swift
public struct Transfer: ABIFunction {
    public static let name = "transfer"
    public let gasPrice: BigUInt? = nil
    public let gasLimit: BigUInt? = nil
    public var contract: EthereumAddress
    public let from: EthereumAddress?

    public let to: EthereumAddress
    public let value: BigUInt

    public init(contract: EthereumAddress,
                from: EthereumAddress? = nil,
                to: EthereumAddress,
                value: BigUInt) {
        self.contract = contract
        self.from = from
        self.to = to
        self.value = value
    }

    public func encode(to encoder: ABIFunctionEncoder) throws {
        try encoder.encode(to)
        try encoder.encode(value)
    }
}
```

This function can be used to generate contract call transactions to send with the client:
```swift
let function = transfer(contract: "0xtokenaddress", from: "0xfrom", to: "0xto", value: 100)
let transaction = try function.transaction()

client.eth_sendRawTransaction(transaction, withAccount: account) { (error, txHash) in
    print("TX Hash: \(txHash)")
}
```
If using `async/await` you can `await` on the result
```swift
let txHash = try await client.eth_sendRawTransaction(transaction, withAccount: account)
```

## Generating ABI from a smart contract ABI file
Currently we don't support code generation as making it properly is a bigger project, and should possibly live outside of this repository. 

You can try this project instead: [imanrep/swiftabigen](https://github.com/imanrep/swiftabigen)

### Data types

The library provides some types and helpers to make interacting with web3 and Ethereum easier.

- `EthereumAddress`: For representation of addresses, including checksum support.
- `BigInt` and `BigUInt`: Using [BigInt](https://github.com/attaswift/BigInt) library
- `EthereumBlock`: Represents the block, either number of RPC-specific definitions like 'Earliest' or 'Latest'
- `EthereumTransaction`: Wraps a transaction. Encoders and decoders can work with it to generate proper `data` fields.

#### Conversion from and to Foundation types

All extensions are namespaced under '<type>'.web3. So for example, to convert an `Int` to a hex string:

```swift
let gwei = 100
let hexgwei = gwei.web3.hexString
```

Supported conversions:
- Convert from hex byte string ("0xabc") to `Data`
- Convert from hex byte string ("0xabc") to `Int`
- Convert from hex byte string ("0xabc") to `BigUInt`
- Convert `String`, `Int`, `BigUInt`, `Data` to a hex byte string ("0xabc")
- Add or remove hex prefixes when working with `String`

### ERC20

We support querying ERC20 token data via the `ERC20` struct. Calls allow to:
- Get the token symbol, name, and decimals
- Get a token balance
- Retrieve `Transfer` events

### ERC721

We support querying ERC721 token data via the `ERC721` struct. Including:
- Get the token symbol, name, and decimals
- Get a token balance
- Retrieve `Transfer` events
- Decode standard JSON for NFT metadata. Please be aware some smart contracts are not 100% compliant with standard.


### ZKSync Era

We also include additional helpers to interact with [ZKSync Era](https://zksync.io/), by importing `web3_zksync`.

Take a look at [ZKSyncTransaction](https://github.com/argentlabs/web3.swift/blob/develop/web3swift/src/ZKSync/ZKSyncTransaction.swift) or use directly
[ZKSyncClient](https://github.com/argentlabs/web3.swift/blob/develop/web3swift/src/ZKSync/ZKSyncProvider.swift) which has similar API as the `EthereumClient`

### Running Tests

Some of the tests require a private key, which is not stored in the repository. You can ignore these while testing locally, as CI will use the encrypted secret key from Github.

It's better to run only the tests you need, instead of the whole test suite while developing. If you ever need to set up the key locally, take a look at `TestConfig.swift` where you can manually set it up. Alternatively you can set it up by calling the script `setupKey.sh` and passing the value (adding 0x) so it's written to an ignored file.

## Dependencies

We built web3.swift to be as lightweight as possible. However, given the cryptographic nature of Ethereum, there's a couple of reliable C libraries you will find packaged with this framework:

- [keccac-tiny](https://github.com/coruus/keccak-tiny): An implementation of the FIPS-202-defined SHA-3 and SHAKE functions in 120 cloc (156 lines).
- [Tiny AES](https://github.com/kokke/tiny-AES-c):  A small and portable implementation of the AES ECB, CTR and CBC encryption algorithms.
- [secp256k1.swift](https://github.com/Boilertalk/secp256k1.swift)

Package dependencies:
- [BigInt](https://github.com/attaswift/BigInt) 
- [GenericJSON](https://github.com/iwill/generic-json-swift)
- [secp256k1](https://github.com/GigaBitcoin/secp256k1.swift.git)
- [Vapor Websocket](https://github.com/vapor/websocket-kit.git)
- [Apple Swift-log](https://github.com/apple/swift-log.git)

Also for Linux build, we can't use Apple crypto APIs, so we embedded a small subset of CryptoSwift (instead of importing the whole library). Credit to [Marcin Krzyżanowski](https://github.com/krzyzanowskim/CryptoSwift)

## Contributors

The initial project was crafted by the team at Argent. However, we encourage anyone to help implement new features and to keep this library up-to-date. For features and fixes, simply submit a pull request to the [develop](https://github.com/argentlabs/web3.swift/tree/develop) branch. Please follow the [contributing guidelines](https://github.com/argentlabs/web3.swift/blob/master/CONTRIBUTING.md).

For bug reports and feature requests, please open an [issue](https://github.com/argentlabs/web3.swift/issues).

## License

Released under the [MIT license](https://github.com/argentlabs/web3.swift/blob/master/LICENSE).
