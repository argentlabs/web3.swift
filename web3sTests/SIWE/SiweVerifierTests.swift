//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import XCTest
@testable import web3

class SiweVerifierTests: XCTestCase {

    var client: EthereumClientProtocol!

    override func setUp() {
        super.setUp()
        if self.client == nil {
            self.client = EthereumHttpClient(url: URL(string: TestConfig.clientUrl)!, network: .sepolia)
        }
    }

    func testNetworkVerification() async {
        let verifier = SiweVerifier(client: client, dateProvider: { Date(timeIntervalSince1970: 1_655_110_800.0) })
        let message = try! SiweMessage(
            domain: "login.xyz",
            address: "0x9d8A62f656a8d1615C1294fd71e9CFb3E4855A4F",
            statement: "You abide to our T&C",
            uri: URL(string: "https://login.xyz/demo#login")!,
            version: "1",
            chainId: 1,
            nonce: "qwerty123456",
            issuedAt: Date(timeIntervalSince1970: 1_655_082_630.023),
            expirationTime: Date(timeIntervalSince1970: 1_657_674_629.0),
            notBefore: Date(timeIntervalSince1970: 1_655_110_800.0),
            requestId: "sample-login-123",
            resources: [
                URL(string: "https://login.xyz")!,
                URL(string: "https://docs.login.xyz")!
            ]
        )

        do {
            _ = try await verifier.verify(message: message, against: "")
            XCTFail("Should have thrown an error")
        } catch SiweVerifier.Error.differentNetwork {
            // Success
        } catch {
            XCTFail("Failed with a different error than expected")
        }
    }

    func testNotBeforeVerification() async {
        let verifier = SiweVerifier(client: client, dateProvider: { Date(timeIntervalSince1970: 1_655_110_799.9) })
        let message = try! SiweMessage(
            domain: "login.xyz",
            address: "0x9d8A62f656a8d1615C1294fd71e9CFb3E4855A4F",
            statement: "You abide to our T&C",
            uri: URL(string: "https://login.xyz/demo#login")!,
            version: "1",
            chainId: 5,
            nonce: "qwerty123456",
            issuedAt: Date(timeIntervalSince1970: 1_655_082_630.023),
            expirationTime: Date(timeIntervalSince1970: 1_657_674_629.0),
            notBefore: Date(timeIntervalSince1970: 1_655_110_800.0),
            requestId: "sample-login-123",
            resources: [
                URL(string: "https://login.xyz")!,
                URL(string: "https://docs.login.xyz")!
            ]
        )

        do {
            _ = try await verifier.verify(message: message, against: "")
            XCTFail("Should have thrown an error")
        } catch SiweVerifier.Error.messageIsNotActiveYet {
            // Success
        } catch {
            XCTFail("Failed with a different error than expected")
        }
    }

    func testExpirationTimeVerification() async {
        let verifier = SiweVerifier(client: client, dateProvider: { Date(timeIntervalSince1970: 1_657_674_629.0) })
        let message = try! SiweMessage(
            domain: "login.xyz",
            address: "0x9d8A62f656a8d1615C1294fd71e9CFb3E4855A4F",
            statement: "You abide to our T&C",
            uri: URL(string: "https://login.xyz/demo#login")!,
            version: "1",
            chainId: 5,
            nonce: "qwerty123456",
            issuedAt: Date(timeIntervalSince1970: 1_655_082_630.023),
            expirationTime: Date(timeIntervalSince1970: 1_657_674_629.0),
            notBefore: Date(timeIntervalSince1970: 1_655_110_800.0),
            requestId: "sample-login-123",
            resources: [
                URL(string: "https://login.xyz")!,
                URL(string: "https://docs.login.xyz")!
            ]
        )

        do {
            _ = try await verifier.verify(message: message, against: "")
            XCTFail("Should have thrown an error")
        } catch SiweVerifier.Error.messageIsExpired {
            // Success
        } catch {
            XCTFail("Failed with a different error than expected")
        }
    }

    func testSignatureVerificationSuccess() async throws {
        let verifier = SiweVerifier(client: client, dateProvider: { Date(timeIntervalSince1970: 1_655_082_630.023) })
        do {
            let isVerified = try await verifier.verify(
                """
                login.xyz wants you to sign in with your Ethereum account:
                0xE78e5ecb061fE3DD1672dDDA7b5116213B23B99A

                Please sign this 🙏

                URI: https://login.xyz/demo#login
                Version: 1
                Chain ID: 11155111
                Nonce: qwerty123456
                Issued At: 2022-06-16T12:09:07.937Z
                Request ID: some-request-id
                Resources:
                - https://docs.login.xyz
                - https://login.xyz
                """,
                against: "0x16a8ed8d9747521909813f75c60961111148978944945226443856fafb2bb93a705e93c465870501b1dd70c7fc15d7d94c6720daa39f9979517aae5e0bdeb94b1b"
            )
            XCTAssertTrue(isVerified)
        } catch {
            XCTFail("Failed with: \(error)")
        }
    }

    func testSignatureVerificationFailure() async throws {
        let verifier = SiweVerifier(client: client, dateProvider: { Date(timeIntervalSince1970: 1_655_082_630.023) })
        do {
            let isVerified = try await verifier.verify(
                """
                login.xyz wants you to sign in with your Ethereum account:
                0xE78e5ecb061fE3DD1672dDDA7b5116213B23B99A

                Please sign this 🙏

                URI: https://login.xyz/demo#login
                Version: 1
                Chain ID: 11155111
                Nonce: qwerty123456
                Issued At: 2022-06-16T12:09:07.937Z
                Request ID: some-request-id
                Resources:
                - https://docs.login.xyz
                - https://login.xyz
                """,
                against: "0x60e700bb8c14da9bc751aee3cb338a763ad9425e7893bd49393fec9f540e9cee1023c42e06989d0b1c04d84b88c62a872073e60218d2c0bc900b5f7f186096611c"
            )
            XCTAssertFalse(isVerified)
        } catch {
            XCTFail("Failed with: \(error)")
        }
    }

    func testSignatureVerificationSuccessUsingERC1271() async throws {
        let verifier = SiweVerifier(client: client, dateProvider: { Date(timeIntervalSince1970: 1_655_082_630.023) })
        do {
            // Notice that the Ethereum account in the message is actually the address of the ERC1271 contract
            let isVerified = try await verifier.verify(
                """
                login.xyz wants you to sign in with your Ethereum account:
                0x9af09A43d0A0EF8cC1b70E543c8502bDA8e3dE61

                Please sign this 🙏

                URI: https://login.xyz/demo#login
                Version: 1
                Chain ID: 11155111
                Nonce: qwerty123456
                Issued At: 2022-06-16T12:09:07.937Z
                Request ID: some-request-id
                Resources:
                - https://docs.login.xyz
                - https://login.xyz
                """,
                against: "0x135afeec25a1e3b25da21aa4c5f5def607366cf75a772a456b19d590d5ac33fe1f679adb73d51ff56089fe6d75d52d296062f325830f10fae186938668e469461b"
            )
            XCTAssertTrue(isVerified)
        } catch {
            XCTFail("Failed with: \(error)")
        }
    }

    func testSignatureVerificationFailureUsingERC1271() async throws {
        let verifier = SiweVerifier(client: client, dateProvider: { Date(timeIntervalSince1970: 1_655_082_630.023) })
        do {
            // Notice that the Ethereum account in the message is actually the address of the ERC1271 contract
            let isVerified = try await verifier.verify(
                """
                login.xyz wants you to sign in with your Ethereum account:
                0x9af09A43d0A0EF8cC1b70E543c8502bDA8e3dE61

                Please sign this 🙏

                URI: https://login.xyz/demo#login
                Version: 1
                Chain ID: 11155111
                Nonce: qwerty123456
                Issued At: 2022-06-16T12:09:07.937Z
                Request ID: some-request-id
                Resources:
                - https://docs.login.xyz
                - https://login.xyz
                """,
                against: "0x16a8ed8d9747521909813f75c60961111148978944945226443856fafb2bb93a705e93c465870501b1dd70c7fc15d7d94c6720daa39f9979517aae5e0bdeb94b1b"
            )
            XCTAssertFalse(isVerified)
        } catch {
            XCTFail("Failed with: \(error)")
        }
    }
}

final class SiweVerifierWebSocketTests: SiweVerifierTests {

    override func setUp() {
        if self.client == nil {
            self.client = EthereumWebSocketClient(url: URL(string: TestConfig.wssUrl)!, network: TestConfig.network)
        }
        super.setUp()
    }
}
