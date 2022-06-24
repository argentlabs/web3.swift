//
//  SiweVerifierTests.swift
//  
//
//  Created by Rodrigo Kreutz on 15/06/22.
//

import XCTest
@testable import web3

class SiweVerifierTests: XCTestCase {

    var client: EthereumClientProtocol!

    override func setUp() {
        super.setUp()
        if self.client == nil {
            self.client = EthereumHttpClient(url: URL(string: TestConfig.clientUrl)!)
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
            chainId: 3,
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
            chainId: 3,
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
                0x9d8A62f656a8d1615C1294fd71e9CFb3E4855A4F

                Please sign this 🙏

                URI: https://login.xyz/demo#login
                Version: 1
                Chain ID: 3
                Nonce: qwerty123456
                Issued At: 2022-06-16T12:09:07.937Z
                Request ID: some-request-id
                Resources:
                - https://docs.login.xyz
                - https://login.xyz
                """,
                against: "0x14ff8392ce953be96f3e57d8519d94f4b19f98cf42d0dca8961c3fa70a12c9857e95f4732839d39e883d26abf0fcdd4602f50acde7721274ea4c31f26981e4b41b"
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
                0x9d8A62f656a8d1615C1294fd71e9CFb3E4855A4F

                Please sign this 🙏

                URI: https://login.xyz/demo#login
                Version: 1
                Chain ID: 3
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
                0x2bD85c85666a29bD453918B20b9E5ef7603d9007

                Please sign this 🙏

                URI: https://login.xyz/demo#login
                Version: 1
                Chain ID: 3
                Nonce: qwerty123456
                Issued At: 2022-06-16T12:09:07.937Z
                Request ID: some-request-id
                Resources:
                - https://docs.login.xyz
                - https://login.xyz
                """,
                against: "0x0217550201eb35af7048e32dbf05201de1440eb079e1046f16cce27463fb5bf56f8c9c33a93845b1e891afdcf60608255433b18435c9cdabca6625fb1bcc41841b"
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
                0x2bD85c85666a29bD453918B20b9E5ef7603d9007

                Please sign this 🙏

                URI: https://login.xyz/demo#login
                Version: 1
                Chain ID: 3
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
}

final class SiweVerifierWebSocketTests: SiweVerifierTests {

    override func setUp() {
        if self.client == nil {
            self.client = EthereumWebSocketClient(url: URL(string: TestConfig.wssUrl)!)
        }
        super.setUp()
    }
}
