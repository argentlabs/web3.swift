//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import XCTest
@testable import web3

// https://github.com/ethereum/EIPs/blob/master/assets/eip-712/Example.js
// https://github.com/dicether/js-eth-personal-sign-examples
class EthereumAccount_SignTypedTests: XCTestCase {
    var account: EthereumAccount!
    let example1 = """
        {
          "types": {
            "EIP712Domain": [
              {
                "name": "name",
                "type": "string"
              },
              {
                "name": "version",
                "type": "string"
              },
              {
                "name": "chainId",
                "type": "uint256"
              },
              {
                "name": "verifyingContract",
                "type": "address"
              }
            ],
            "Person": [
              {
                "name": "name",
                "type": "string"
              },
              {
                "name": "wallet",
                "type": "address"
              }
            ],
            "Mail": [
              {
                "name": "from",
                "type": "Person"
              },
              {
                "name": "to",
                "type": "Person"
              },
              {
                "name": "contents",
                "type": "string"
              }
            ]
          },
          "primaryType": "Mail",
          "domain": {
            "name": "Ether Mail",
            "version": "1",
            "chainId": 1,
            "verifyingContract": "0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC"
          },
          "message": {
            "from": {
              "name": "Cow",
              "wallet": "0xCD2a3d9F938E13CD947Ec05AbC7FE734Df8DD826"
            },
            "to": {
              "name": "Bob",
              "wallet": "0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB"
            },
            "contents": "Hello, Bob!"
          }
        }
    """.data(using: .utf8)!

    let noDomain = """
        {
          "types" : {
            "EIP712Domain":[],
            "Test":[
              { "name": "test", "type": "uint64"}
            ]
          },
          "primaryType":"Test",
          "domain": {},
          "message": {
            "test": 1,
          }
        }
    """.data(using: .utf8)!

    let example2 = """
        {
          "types": {
              "EIP712Domain": [
                  {"name": "name", "type": "string"},
                  {"name": "version", "type": "string"},
                  {"name": "chainId", "type": "uint256"},
                  {"name": "verifyingContract", "type": "address"}
              ],
              "Person": [
                  {"name": "name", "type": "string"},
                  {"name": "wallet", "type": "bytes32"},
                  {"name": "age", "type": "int256"},
                  {"name": "paid", "type": "bool"}
              ]
          },
          "primaryType": "Person",
          "domain": {
              "name": "Person",
              "version": "1",
              "chainId": 1,
              "verifyingContract": "0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC"
          },
          "message": {
              "name": "alice",
              "wallet": "0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB",
              "age": 40,
              "paid": true
            }
        }
    """.data(using: .utf8)!

    let example3 = """
    {"types":{"EIP712Domain":[{"name":"name","type":"string"},{"name":"version","type":"string"},{"name":"verifyingContract","type":"address"}],"RelayRequest":[{"name":"target","type":"address"},{"name":"encodedFunction","type":"bytes"},{"name":"gasData","type":"GasData"},{"name":"relayData","type":"RelayData"}],"GasData":[{"name":"gasLimit","type":"uint256"},{"name":"gasPrice","type":"uint256"},{"name":"pctRelayFee","type":"uint256"},{"name":"baseRelayFee","type":"uint256"}],"RelayData":[{"name":"senderAddress","type":"address"},{"name":"senderNonce","type":"uint256"},{"name":"relayWorker","type":"address"},{"name":"paymaster","type":"address"}]},"domain":{"name":"GSN Relayed Transaction","version":"1","chainId":42,"verifyingContract":"0x6453D37248Ab2C16eBd1A8f782a2CBC65860E60B"},"primaryType":"RelayRequest","message":{"target":"0x9cf40ef3d1622efe270fe6fe720585b4be4eeeff","encodedFunction":"0xa9059cbb0000000000000000000000002e0d94754b348d208d64d52d78bcd443afa9fa520000000000000000000000000000000000000000000000000000000000000007","gasData":{"gasLimit":"39507","gasPrice":"1700000000","pctRelayFee":"70","baseRelayFee":"0"},"relayData":{"senderAddress":"0x22d491bde2303f2f43325b2108d26f1eaba1e32b","senderNonce":"3","relayWorker":"0x3baee457ad824c94bd3953183d725847d023a2cf","paymaster":"0x957F270d45e9Ceca5c5af2b49f1b5dC1Abb0421c"}}}
    """.data(using: .utf8)!

    let example4 = """
    {
      "types": {
          "EIP712Domain": [
              {"name": "verifyingContract", "type": "address"},
              {"name": "chainId", "type": "uint256"},
          ],
          "TxMessage": [
              {"name": "signer", "type": "address"},
              {"name": "to", "type": "address"},
              {"name": "data", "type": "bytes"},
              {"name": "nonce", "type": "uint256"}
          ]
      },
      "primaryType": "TxMessage",
      "domain": {
          "chainId": 3,
          "verifyingContract": "0x9f733Fd052A5526cdc646E178c684B1Bf2313C57"
      },
      "message": {
          "signer": "0x2c68bfBc6F2274E7011Cd4AB8D5c0e69B2341309",
          "to": "0x68f3cEdf21B0f9ce31AAdC5ed110014Af5DA1828",
          "data": "0xa21f3c6a68656c6c6f000000000000000000000000000000000000000000000000000000776f726c64202100000000000000000000000000000000000000000000000000",
          "nonce": 0
        }
    }
    """.data(using: .utf8)!

    let decoder = JSONDecoder()

    override func setUp() {
        let keyStorage = EthereumKeyLocalStorage()
        try! keyStorage.storePrivateKey(key: "cow".web3.keccak256)
        account = try! EthereumAccount(keyStorage: keyStorage)
    }

    func test_GivenExample_TypeHashIsCorrect() {
        let typedData = try! decoder.decode(TypedData.self, from: example1)

        XCTAssertEqual(typedData.typeHash.web3.hexString, "0xa0cedeb2dc280ba39b857546d74f5549c3a1d7bdc2dd96bf881f76108e23dac2")
    }

    func test_GivenExample_EncodesType() {
        let typedData = try! decoder.decode(TypedData.self, from: example1)

        XCTAssertEqual(typedData.encodeType(primaryType: "Mail"), "Mail(Person from,Person to,string contents)Person(string name,address wallet)".data(using: .utf8)!)
    }

    func test_GivenExample_EncodesMessage() {
        let typedData = try! decoder.decode(TypedData.self, from: example1)

        let data = try! typedData.encodeData(data: typedData.message, type: typedData.primaryType)
        XCTAssertEqual(data.web3.hexString, "0xa0cedeb2dc280ba39b857546d74f5549c3a1d7bdc2dd96bf881f76108e23dac2fc71e5fa27ff56c350aa531bc129ebdf613b772b6604664f5d8dbe21b85eb0c8cd54f074a4af31b4411ff6a60c9719dbd559c221c8ac3492d9d872b041d703d1b5aadf3154a261abdd9086fc627b61efca26ae5702701d05cd2305f7c52a2fc8")
    }

    func test_GivenExample_HashesMessage() {
        let typedData = try! decoder.decode(TypedData.self, from: example1)
        let data = try! typedData.encodeData(data: typedData.message, type: typedData.primaryType)
        XCTAssertEqual(data.web3.keccak256.web3.hexString, "0xc52c0ee5d84264471806290a3f2c4cecfc5490626bf912d01f240d7a274b371e")
    }

    func test_GivenExample_HashesDomain() {
        let typedData = try! decoder.decode(TypedData.self, from: example1)
        let data = try! typedData.encodeData(data: typedData.domain, type: "EIP712Domain")
        XCTAssertEqual(data.web3.keccak256.web3.hexString, "0xf2cee375fa42b42143804025fc449deafd50cc031ca257e0b194a650a912090f")
    }

    func test_GivenExample_ItHashesCorrectly() {
        let typedData = try! decoder.decode(TypedData.self, from: example1)
        XCTAssertEqual(try! typedData.signableHash().web3.hexString, "0xbe609aee343fb3c4b28e1df9e632fca64fcfaede20f02e86244efddf30957bd2")
    }

    func test_GivenSmallerExample_ItEncodesCorrectly() {
        let typedData = try! decoder.decode(TypedData.self, from: example2)
        XCTAssertEqual(try! typedData.encodeData(data: typedData.message, type: typedData.primaryType).web3.hexString,
                       "0x432c2e85cd4fb1991e30556bafe6d78422c6eeb812929bc1d2d4c7053998a4099c0257114eb9399a2985f8e75dad7600c5d89fe3824ffa99ec1c3eb8bf3b0501bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000280000000000000000000000000000000000000000000000000000000000000001")
    }

    func test_GivenWalletConnectExample_ItEncodesCorrectly() {
        let typedData = try! decoder.decode(TypedData.self, from: example3)
        XCTAssertEqual(try! typedData.encodeData(data: typedData.message, type: typedData.primaryType).web3.hexString,
                       "0x2ff8cad9fc52c931beef9178a726d1ab6280a9c2b6a6396450a181819cf1e5400000000000000000000000009cf40ef3d1622efe270fe6fe720585b4be4eeeffa9485354dd9d340e02789cfc540c6c4a2ff5511beb414b64634a5e11c6a7168cff9bf07e24e6ff0943eadc198a43500e4016d41517b01c92d4b2217909610371b070fcfff74c07b7820d93159a2fd5cb8e2fdf060ee7b42e79f1b4414bccccc1")
    }

    func test_GivenWalletConnectExample_ItHashesCorrectly() {
        let typedData = try! decoder.decode(TypedData.self, from: example3)
        XCTAssertEqual(try! typedData.signableHash().web3.hexString,
                       "0xabc79f527273b9e7bca1b3f1ac6ad1a8431fa6dc34ece900deabcd6969856b5e")
    }

    func test_GivenNoDomain_ItHashesCorrectly() {
        let typedData = try! decoder.decode(TypedData.self, from: noDomain)
        XCTAssertEqual(try! typedData.signableHash().web3.hexString,
                       "0x34091011761262618af3045f97715b4a73eb6737c9396353b85b757201e3ad9f")
    }

    func test_GivenProdExample_ItHashesCorrectly() {
        let url = Bundle.module.url(forResource: "cryptofights_712", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        let typedData = try! decoder.decode(TypedData.self, from: data)
        XCTAssertEqual(try! typedData.signableHash().web3.hexString, "0xdb12328a6d193965801548e1174936c3aa7adbe1b54b3535a3c905bd4966467c")
    }
    
    func test_GivenCustomTypeArray_V4_ItHashesCorrectly() {
        let simpleUrl = Bundle.module.url(forResource: "ethermail_signTypedDataV4", withExtension: "json")!
        let simpleData = try! Data(contentsOf: simpleUrl)
        let simpleTypedData = try! decoder.decode(TypedData.self, from: simpleData)
        XCTAssertEqual(try! simpleTypedData.signableHash().web3.hexString, "0x8a2c45f690057d91a9738b313da3f65916327e1d5b9a1348b9fc1cff0dc4091e")
        
        let realWorldUrl = Bundle.module.url(forResource: "real_word_opensea_signTypedDataV4", withExtension: "json")!
        let realWorldData = try! Data(contentsOf: realWorldUrl)
        let realWorldTypedData = try! decoder.decode(TypedData.self, from: realWorldData)
        XCTAssertEqual(try! realWorldTypedData.signableHash().web3.hexString, "0x76a61293096587b582305a07a60785f92b99ae6c8647c4bcf46d6651db0bd778")
    }

    func test_givenExampleWithDynamicData_ItHashesCorrectly() {
        let typedData = try! decoder.decode(TypedData.self, from: example4)
        XCTAssertEqual(try! typedData.signableHash().web3.hexString,
                       "0x1f177092c4fbedf53f392389d4512f0a61babf07acc05303a4f1ef7e90b67d92")

    }

    func test_givenExample_ItSignsCorrectly() {
        let typedData = try! decoder.decode(TypedData.self, from: example1)
        let signed = try? account.signMessage(message: typedData)
        XCTAssertEqual(signed, "0x4355c47d63924e8a72e509b65029052eb6c299d53a04e167c5775fd466751c9d07299936d304c153f6443dfa05f40ff007d72911b6f72307f996231605b915621c")
    }
}
