//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import XCTest
@testable import web3

class SIWETests: XCTestCase {

    var client: EthereumClientProtocol!
    var verifier: SiweVerifier!

    override func setUp() {
        super.setUp()
        if self.client == nil {
            self.client = EthereumHttpClient(url: URL(string: TestConfig.clientUrl)!)
        }
        self.verifier = SiweVerifier(client: self.client)
    }

    func testEndToEnd() async {
        let privateKey = "0x4646464646464646464646464646464646464646464646464646464646464646"
        let address = "0x9d8a62f656a8d1615c1294fd71e9cfb3e4855a4f"
        let account = EthereumAccount(address: .init(address), keyStorage: TestEthereumKeyStorage(privateKey: privateKey))
        let message = try! SiweMessage(
            """
            login.xyz wants you to sign in with your Ethereum account:
            \(account.address.toChecksumAddress())

            Please sign this 🙏

            URI: https://login.xyz/demo#login
            Version: 1
            Chain ID: 5
            Nonce: qwerty123456
            Issued At: \(SiweMessage.dateFormatter.string(from: Date()))
            Expiration Time: \(SiweMessage.dateFormatter.string(from: Date(timeInterval: 60, since: Date())))
            Not Before: \(SiweMessage.dateFormatter.string(from: Date(timeInterval: -60, since: Date())))
            Request ID: some-request-id
            Resources:
            - https://docs.login.xyz
            - https://login.xyz
            """
        )

        var signature: String = ""
        do {
            signature = try await account.signSIWERequest(message)
        } catch {
            XCTFail(error.localizedDescription)
        }

        var isValid = false
        do {
            isValid = try await verifier.verify(message: message, against: signature)
            XCTAssertTrue(isValid)
        } catch {
            XCTFail("Error thrown while verifying signature: \(error)")
        }
    }
}

final class SIWEWebSocketTests: SIWETests {

    override func setUp() {
        if self.client == nil {
            self.client = EthereumWebSocketClient(url: URL(string: TestConfig.wssUrl)!)
        }
        super.setUp()
    }
}
