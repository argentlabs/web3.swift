![web3.swift: Ethereum API for Swift](https://raw.githubusercontent.com/argentlabs/web3.swift/master/web3swift.png)

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
let keyStorage = EthereumKeyLocalStorage()
let account = try? EthereumAccount.create(keyStorage: keyStorage, keystorePassword: "MY_PASSWORD")
```

Create an instance of `EthereumClient`. This will then provide you access to a set of functions for interacting with the Blockchain.

```
guard let clientUrl = URL("https://an-infura-or-similar-url.com/123") else { return }
let client = EthereumClient(url: clientUrl)
```

You can then interact with the client methods, such as to get the current gas price:

```
client.eth_getPrice { (error, currentPrice) in
    print("The current gas price is \(currentPrice)")
}
```

For more advanced use, you will find support for Ethereum Name Service and smart contract parsing.


### Running Tests

The tests will all pass when running against Ropsten. You will need to provide a URL for the blockchain proxy (e.g. on Infura), and a key-pair in `TestConfig.swift`. Some of the account signing tests will fail, given the signature assertions are against a specific (unprovided) key.

## Dependencies

We built web3.swift to be as lightweight as possible. However, given the cryptographic nature of Ethereum, there's a couple of reliable C libraries you will find packaged with this framework:

- [keccac-tiny](https://github.com/coruus/keccak-tiny): An implementation of the FIPS-202-defined SHA-3 and SHAKE functions in 120 cloc (156 lines).
- [secp256k1](https://github.com/bakkenbaeck/EtherealCereal): For EC operations on curve secp256k1.
- [Tiny AES](https://github.com/kokke/tiny-AES-c):  A small and portable implementation of the AES ECB, CTR and CBC encryption algorithms.

We also use Apple's own CommonCrypto (via [this](https://github.com/sergejp/CommonCrypto) method) and [BigInt](https://github.com/attaswift/BigInt) via CocoaPod dependency.

## Todos

There's some features that have yet to be fully implemented! Not every RPC method is currently supported, and here's some other suggestions we would like to see in the future:

- ABI encoding support for tuples
- Batch support for JSONRPC interface
- Use a Hex struct for values to be more explicit in expected types
- Use [Truffle](https://github.com/trufflesuite/ganache-cli) for running tests
- Add support for Carthage and Swift Package Manager
- Bloom Filter support
- ERC20 token support

## Contributors

The initial project was crafted by the team at Argent. However, we encorage anyone to help implement new features and to keep this library up-to-date. For features and fixes, simply submit a pull request to the develop branch. Please follow the [contributing guidelines](https://github.com/argentlabs/web3.swift/blob/master/CONTRIBUTING.md).

For bug reports and feature requests, please open an [issue](https://github.com/argentlabs/web3.swift/issues).

## License

Released under the [MIT license](https://github.com/argentlabs/web3.swift/blob/master/LICENSE).
