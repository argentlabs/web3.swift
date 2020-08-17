![web3.swift: Ethereum API for Swift](https://raw.github.com/argentlabs/web3.swift/master/web3swift.png)

[![Build Status](https://app.bitrise.io/app/c65202fce1ab4f66/status.svg?token=3G01KrQCcivwF5puzFd0PA&branch=develop)](https://app.bitrise.io/app/c65202fce1ab4f66)

## Installation

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

Create an instance of `EthereumAccount`  with a `EthereumKeyStorage` provider. This provides a wrapper around your key for web3.swift to use. **NOTE** We recommend you implement your own KeyStorage provider, instead of relying on the provided `EthereumKeyLocalStorage` class. This is provided as an example for conformity to the `EthereumKeyStorageProtocol`.

```bash
import web3


let keyStorage = EthereumKeyLocalStorage()
let account = try? EthereumAccount.create(keyStorage: keyStorage, keystorePassword: "MY_PASSWORD")
```

Create an instance of `EthereumClient`. This will then provide you access to a set of functions for interacting with the Blockchain.

```
guard let clientUrl = URL(string: "https://an-infura-or-similar-url.com/123") else { return }
let client = EthereumClient(url: clientUrl)
```

You can then interact with the client methods, such as to get the current gas price:

```
client.eth_gasPrice { (error, currentPrice) in
    print("The current gas price is \(currentPrice)")
}
```

### Smart contracts: Static types

Given a smart contract function ABI like ERC20 `transfer`:
```
function transfer(address recipient, uint256 amount) public returns (bool)
```

then you can define an `ABIFunction` with corresponding encodable Swift types like so:
```
public struct transfer: ABIFunction {
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
```
let function = transfer(contract: EthereumAddress("0xtokenaddress"), from: EthereumAddress("0xfrom"), to: EthereumAddress("0xto"), value: 100)
let transaction = try function.transaction()

client.eth_sendRawTransaction(transacton, withAccount: account) { (error, txHash) in
    print("TX Hash: \(txHash)")
}
```

### Data types

The library provides some types and helpers to make interacting with web3 and Ethereum easier.

- `EthereumAddress`: For representation of addresses, including checksum support.
- `BigInt` and `BigUInt`: Using [BigInt](https://github.com/attaswift/BigInt) library
- `EthereumBlock`: Represents the block, either number of RPC-specific defintions like 'Earliest' or 'Latest'
- `EthereumTransaction`: Wraps a transaction. Encoders and decoders can work with it to generate proper `data` fields.

#### Conversion from and to Foundation types

All extensions are namespaced under '<type>'.web3. So for example, to convert an `Int` to a hex string:

```
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

### Running Tests

The tests will all pass when running against Ropsten. You will need to provide a URL for the blockchain proxy (e.g. on Infura), and a key-pair in `TestConfig.swift`. Some of the account signing tests will fail, given the signature assertions are against a specific (unprovided) key.

## Dependencies

We built web3.swift to be as lightweight as possible. However, given the cryptographic nature of Ethereum, there's a couple of reliable C libraries you will find packaged with this framework:

- [keccac-tiny](https://github.com/coruus/keccak-tiny): An implementation of the FIPS-202-defined SHA-3 and SHAKE functions in 120 cloc (156 lines).
- [Tiny AES](https://github.com/kokke/tiny-AES-c):  A small and portable implementation of the AES ECB, CTR and CBC encryption algorithms.
- [secp256k1.swift](https://github.com/Boilertalk/secp256k1.swift)

We also use Apple's own CommonCrypto (via [this](https://github.com/sergejp/CommonCrypto) method) and [BigInt](https://github.com/attaswift/BigInt) via CocoaPod dependency.

## Todos

There are some features that have yet to be fully implemented! Not every RPC method is currently supported, and here's some other suggestions we would like to see in the future:


- Batch support for JSONRPC interface
- Use a Hex struct for values to be more explicit in expected types
- Use [Truffle](https://github.com/trufflesuite/ganache-cli) for running tests
- Add support for Swift Package Manager
- Bloom Filter support
- Full ERC20 token support of totalSupply, allowance, transfer, approve, transferFrom, and Transfer/Approval events

## Contributors

The initial project was crafted by the team at Argent. However, we encourage anyone to help implement new features and to keep this library up-to-date. For features and fixes, simply submit a pull request to the [develop](https://github.com/argentlabs/web3.swift/tree/develop) branch. Please follow the [contributing guidelines](https://github.com/argentlabs/web3.swift/blob/master/CONTRIBUTING.md).

For bug reports and feature requests, please open an [issue](https://github.com/argentlabs/web3.swift/issues).

## License

Released under the [MIT license](https://github.com/argentlabs/web3.swift/blob/master/LICENSE).
