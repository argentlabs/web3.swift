//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import XCTest
@testable import web3

class ERC1271Tests: XCTestCase {
    var client: EthereumClientProtocol!
    var erc1271: ERC1271!

    override func setUp() {
        super.setUp()
        if self.client == nil {
            self.client = EthereumHttpClient(url: URL(string: TestConfig.clientUrl)!, network: TestConfig.network)
        }
        // Expected owner 0x64d0eA4FC60f27E74f1a70Aa6f39D403bBe56793
        self.erc1271 = ERC1271(client: self.client)
    }

    override func tearDown() {
        super.tearDown()
    }

    func testSuccesfulVerificationWithMagicNumberContract() async {
        do {
            let isValid = try await erc1271.isValidSignature(
                contract: EthereumAddress("0x9af09A43d0A0EF8cC1b70E543c8502bDA8e3dE61"),
                messageHash: "0x50b2c43fd39106bafbba0da34fc430e1f91e3c96ea2acee2bc34119f92b37750".web3.hexData!,
                signature: "0x44632b4bebf8a8817899aa90036285c884aa197c72da6ac11612a2ca59f1fcd76aa41ac92b961a4693b213513f5fdf1f509b7f52d439d1c09422af7eaa69f0d11c".web3.hexData!
            )
            XCTAssertTrue(isValid)
        } catch {
            XCTFail("Failed with: \(error)")
        }
    }

    func testSuccessfulVerificationWithBooleanContract() async {
        do {
            let isValid = try await erc1271.isValidSignature(
                contract: EthereumAddress("0x2D7e2752b3DFa868f58Cf8FA8FF0D73b31F035a1"),
                messageHash: "0x50b2c43fd39106bafbba0da34fc430e1f91e3c96ea2acee2bc34119f92b37750".web3.hexData!,
                signature: "0x44632b4bebf8a8817899aa90036285c884aa197c72da6ac11612a2ca59f1fcd76aa41ac92b961a4693b213513f5fdf1f509b7f52d439d1c09422af7eaa69f0d11c".web3.hexData!
            )
            XCTAssertTrue(isValid)
        } catch {
            XCTFail("Failed with: \(error)")
        }
    }

    func testFailedVerification() async {
        do {
            // Here the signature and the hash matches, but the contract will say is invalid cause the signer is not the owner of the contract
            let isValid = try await erc1271.isValidSignature(
                contract: EthereumAddress("0x9af09A43d0A0EF8cC1b70E543c8502bDA8e3dE61"),
                messageHash: "0x50b2c43fd39106bafbba0da34fc430e1f91e3c96ea2acee2bc34119f92b37750".web3.hexData!,
                signature: "0x8e2ba38942cd698e4a47fc5227c61b94c9458f9093daa051bb87f57ebfd929280181f9f375d28864d4d9c1d24a29e0a2142d721669f737731d738c02b3ab89981b".web3.hexData!
            )
            XCTAssertFalse(isValid)
        } catch {
            XCTFail("Failed with: \(error)")
        }

        do {
            // Here the signature and the hash don't match
            let isValid = try await erc1271.isValidSignature(
                contract: EthereumAddress("0x9af09A43d0A0EF8cC1b70E543c8502bDA8e3dE61"),
                messageHash: "0x50b2c43fd39106bafbba0da34fc430e1f91e3c96ea2acee2bc34119f92b37750".web3.hexData!,
                signature: "0xe0c97bb5b8bc876636598132f0b4a250b94bb0d0b95dde49edbbacd1835c62ae301cc27f7117bf362973c64e100edee9c1c4a2ae52503c1a4cb621ec58e7f4521b".web3.hexData!
            )
            XCTAssertFalse(isValid)
        } catch {
            XCTFail("Failed with: \(error)")
        }
    }

    func testFailedVerificationWithBooleanContract() async {
        do {
            // Here the signature and the hash matches, but the contract will say is invalid cause the signer is not the owner of the contract
            let isValid = try await erc1271.isValidSignature(
                contract: EthereumAddress("0x2D7e2752b3DFa868f58Cf8FA8FF0D73b31F035a1"),
                messageHash: "0x50b2c43fd39106bafbba0da34fc430e1f91e3c96ea2acee2bc34119f92b37750".web3.hexData!,
                signature: "0x8e2ba38942cd698e4a47fc5227c61b94c9458f9093daa051bb87f57ebfd929280181f9f375d28864d4d9c1d24a29e0a2142d721669f737731d738c02b3ab89981b".web3.hexData!
            )
            XCTAssertFalse(isValid)
        } catch {
            XCTFail("Failed with: \(error)")
        }

        do {
            // Here the signature and the hash don't match
            let isValid = try await erc1271.isValidSignature(
                contract: EthereumAddress("0x2D7e2752b3DFa868f58Cf8FA8FF0D73b31F035a1"),
                messageHash: "0x50b2c43fd39106bafbba0da34fc430e1f91e3c96ea2acee2bc34119f92b37750".web3.hexData!,
                signature: "0xe0c97bb5b8bc876636598132f0b4a250b94bb0d0b95dde49edbbacd1835c62ae301cc27f7117bf362973c64e100edee9c1c4a2ae52503c1a4cb621ec58e7f4521b".web3.hexData!
            )
            XCTAssertFalse(isValid)
        } catch {
            XCTFail("Failed with: \(error)")
        }
    }
}

final class ERC1271WebSocketTests: ERC1271Tests {

    override func setUp() {
        if self.client == nil {
            self.client = EthereumWebSocketClient(url: URL(string: TestConfig.wssUrl)!, network: TestConfig.network)
        }
        super.setUp()
    }
}
