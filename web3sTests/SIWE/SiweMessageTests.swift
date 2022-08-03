//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import XCTest
@testable import web3

final class SiweMessageTests: XCTestCase {

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        return formatter
    }()

    func testFullJsonDecoding() {
        let json = """
        {
            "domain": "login.xyz",
            "address": "0x9d8A62f656a8d1615C1294fd71e9CFb3E4855A4F",
            "statement": "You abide to our T&C",
            "uri": "https://login.xyz/demo#login",
            "version": "1",
            "chainId": 1,
            "nonce": "qwerty123456",
            "issuedAt": "2022-06-13T01:10:30.023Z",
            "expirationTime": "2022-07-13T01:10:29.000Z",
            "notBefore": "2022-06-13T09:00:00.000Z",
            "requestId": "sample-login-123",
            "resources": [
                "https://login.xyz",
                "https://docs.login.xyz"
            ]
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(SiweMessageTests.dateFormatter)
        var message: SiweMessage?
        XCTAssertNoThrow(message = try decoder.decode(SiweMessage.self, from: json))
        XCTAssertEqual(
            message,
            try! SiweMessage(
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
        )
    }

    func testMinimalJsonDecoding() {
        let json = """
        {
            "domain": "login.xyz",
            "address": "0x9d8A62f656a8d1615C1294fd71e9CFb3E4855A4F",
            "uri": "https://login.xyz/demo#login",
            "version": "1",
            "chainId": 1,
            "nonce": "qwerty123456",
            "issuedAt": "2022-06-13T01:10:30.023Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(SiweMessageTests.dateFormatter)
        var message: SiweMessage?
        XCTAssertNoThrow(message = try decoder.decode(SiweMessage.self, from: json))
        XCTAssertEqual(
            message,
            try! SiweMessage(
                domain: "login.xyz",
                address: "0x9d8A62f656a8d1615C1294fd71e9CFb3E4855A4F",
                statement: nil,
                uri: URL(string: "https://login.xyz/demo#login")!,
                version: "1",
                chainId: 1,
                nonce: "qwerty123456",
                issuedAt: Date(timeIntervalSince1970: 1_655_082_630.023),
                expirationTime: nil,
                notBefore: nil,
                requestId: nil,
                resources: nil
            )
        )
    }

    func testFullJsonEncoding() {
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

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(SiweMessageTests.dateFormatter)
        var messageData: Data?
        XCTAssertNoThrow(messageData = try encoder.encode(message).asJson(with: [.prettyPrinted, .sortedKeys]))
        XCTAssertEqual(
            messageData,
            """
            {
                "domain": "login.xyz",
                "address": "0x9d8A62f656a8d1615C1294fd71e9CFb3E4855A4F",
                "statement": "You abide to our T&C",
                "uri": "https://login.xyz/demo#login",
                "version": "1",
                "chainId": 1,
                "nonce": "qwerty123456",
                "issuedAt": "2022-06-13T01:10:30.023Z",
                "expirationTime": "2022-07-13T01:10:29.000Z",
                "notBefore": "2022-06-13T09:00:00.000Z",
                "requestId": "sample-login-123",
                "resources": [
                    "https://login.xyz",
                    "https://docs.login.xyz"
                ]
            }
            """.data(using: .utf8)!.asJson(with: [.prettyPrinted, .sortedKeys])
        )
    }

    func testMinimalJsonEncoding() {
        let message = try! SiweMessage(
            domain: "login.xyz",
            address: "0x9d8A62f656a8d1615C1294fd71e9CFb3E4855A4F",
            statement: nil,
            uri: URL(string: "https://login.xyz/demo#login")!,
            version: "1",
            chainId: 1,
            nonce: "qwerty123456",
            issuedAt: Date(timeIntervalSince1970: 1_655_082_630.023),
            expirationTime: nil,
            notBefore: nil,
            requestId: nil,
            resources: nil
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(SiweMessageTests.dateFormatter)
        var messageData: Data?
        XCTAssertNoThrow(messageData = try encoder.encode(message).asJson(with: [.prettyPrinted, .sortedKeys]))
        XCTAssertEqual(
            messageData,
            """
            {
                "domain": "login.xyz",
                "address": "0x9d8A62f656a8d1615C1294fd71e9CFb3E4855A4F",
                "uri": "https://login.xyz/demo#login",
                "version": "1",
                "chainId": 1,
                "nonce": "qwerty123456",
                "issuedAt": "2022-06-13T01:10:30.023Z"
            }
            """.data(using: .utf8)!.asJson(with: [.prettyPrinted, .sortedKeys])
        )
    }

    func testFullMessageString() {
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

        XCTAssertEqual(
            "\(message)",
            """
            login.xyz wants you to sign in with your Ethereum account:
            0x9d8A62f656a8d1615C1294fd71e9CFb3E4855A4F

            You abide to our T&C

            URI: https://login.xyz/demo#login
            Version: 1
            Chain ID: 1
            Nonce: qwerty123456
            Issued At: 2022-06-13T01:10:30.023Z
            Expiration Time: 2022-07-13T01:10:29.000Z
            Not Before: 2022-06-13T09:00:00.000Z
            Request ID: sample-login-123
            Resources:
            - https://login.xyz
            - https://docs.login.xyz
            """
        )
    }

    func testMinimalMessageString() {
        let message = try! SiweMessage(
            domain: "login.xyz",
            address: "0x9d8A62f656a8d1615C1294fd71e9CFb3E4855A4F",
            statement: nil,
            uri: URL(string: "https://login.xyz/demo#login")!,
            version: "1",
            chainId: 1,
            nonce: "qwerty123456",
            issuedAt: Date(timeIntervalSince1970: 1_655_082_630.023),
            expirationTime: nil,
            notBefore: nil,
            requestId: nil,
            resources: nil
        )

        XCTAssertEqual(
            "\(message)",
            """
            login.xyz wants you to sign in with your Ethereum account:
            0x9d8A62f656a8d1615C1294fd71e9CFb3E4855A4F


            URI: https://login.xyz/demo#login
            Version: 1
            Chain ID: 1
            Nonce: qwerty123456
            Issued At: 2022-06-13T01:10:30.023Z
            """
        )
    }

    func testFullMessageRegExParsing() {
        let message = try! SiweMessage(fromStringUsingRegEx: """
            login.xyz wants you to sign in with your Ethereum account:
            0x9d8A62f656a8d1615C1294fd71e9CFb3E4855A4F

            You abide to our T&C

            URI: https://login.xyz/demo#login
            Version: 1
            Chain ID: 1
            Nonce: qwerty123456
            Issued At: 2022-06-13T01:10:30.023Z
            Expiration Time: 2022-07-13T01:10:29.000Z
            Not Before: 2022-06-13T09:00:00.000Z
            Request ID: sample-login-123
            Resources:
            - https://login.xyz
            - https://docs.login.xyz
            """
        )

        XCTAssertEqual(
            message,
            try! SiweMessage(
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
        )
    }

    func testMinimalMessageRegExParsing() {
        let message = try! SiweMessage(fromStringUsingRegEx: """
            login.xyz wants you to sign in with your Ethereum account:
            0x9d8A62f656a8d1615C1294fd71e9CFb3E4855A4F


            URI: https://login.xyz/demo#login
            Version: 1
            Chain ID: 1
            Nonce: qwerty123456
            Issued At: 2022-06-13T01:10:30.023Z
            """
        )

        XCTAssertEqual(
            message,
            try! SiweMessage(
                domain: "login.xyz",
                address: "0x9d8A62f656a8d1615C1294fd71e9CFb3E4855A4F",
                statement: nil,
                uri: URL(string: "https://login.xyz/demo#login")!,
                version: "1",
                chainId: 1,
                nonce: "qwerty123456",
                issuedAt: Date(timeIntervalSince1970: 1_655_082_630.023),
                expirationTime: nil,
                notBefore: nil,
                requestId: nil,
                resources: nil
            )
        )
    }

    func testDomainValidation() {
        var message = try! SiweMessage(
            domain: "login.xyz",
            address: "0x9d8A62f656a8d1615C1294fd71e9CFb3E4855A4F",
            statement: nil,
            uri: URL(string: "https://login.xyz/demo#login")!,
            version: "1",
            chainId: 1,
            nonce: "qwerty123456",
            issuedAt: Date(timeIntervalSince1970: 1_655_082_630.023),
            expirationTime: nil,
            notBefore: nil,
            requestId: nil,
            resources: nil
        )

        XCTAssertNoThrow(try message.validate())

        message.domain = ""

        XCTAssertThrowsError(try message.validate())
    }

    func testAddressValidation() {
        var message = try! SiweMessage(
            domain: "login.xyz",
            address: "0x9d8A62f656a8d1615C1294fd71e9CFb3E4855A4F",
            statement: nil,
            uri: URL(string: "https://login.xyz/demo#login")!,
            version: "1",
            chainId: 1,
            nonce: "qwerty123456",
            issuedAt: Date(timeIntervalSince1970: 1_655_082_630.023),
            expirationTime: nil,
            notBefore: nil,
            requestId: nil,
            resources: nil
        )

        XCTAssertNoThrow(try message.validate())

        message.address = "0x9d8A62f656a8d1615C1294fd71e9CFb3E4855A4F".lowercased()

        XCTAssertThrowsError(try message.validate())
    }

    func testVersionValidation() {
        var message = try! SiweMessage(
            domain: "login.xyz",
            address: "0x9d8A62f656a8d1615C1294fd71e9CFb3E4855A4F",
            statement: nil,
            uri: URL(string: "https://login.xyz/demo#login")!,
            version: "1",
            chainId: 1,
            nonce: "qwerty123456",
            issuedAt: Date(timeIntervalSince1970: 1_655_082_630.023),
            expirationTime: nil,
            notBefore: nil,
            requestId: nil,
            resources: nil
        )

        XCTAssertNoThrow(try message.validate())

        message.version = "2"

        XCTAssertThrowsError(try message.validate())
    }

    func testChainIdValidation() {
        var message = try! SiweMessage(
            domain: "login.xyz",
            address: "0x9d8A62f656a8d1615C1294fd71e9CFb3E4855A4F",
            statement: nil,
            uri: URL(string: "https://login.xyz/demo#login")!,
            version: "1",
            chainId: 1,
            nonce: "qwerty123456",
            issuedAt: Date(timeIntervalSince1970: 1_655_082_630.023),
            expirationTime: nil,
            notBefore: nil,
            requestId: nil,
            resources: nil
        )

        XCTAssertNoThrow(try message.validate())

        message.chainId = 0

        XCTAssertThrowsError(try message.validate())

        message.chainId = -1

        XCTAssertThrowsError(try message.validate())
    }

    func testNonceValidation() {
        var message = try! SiweMessage(
            domain: "login.xyz",
            address: "0x9d8A62f656a8d1615C1294fd71e9CFb3E4855A4F",
            statement: nil,
            uri: URL(string: "https://login.xyz/demo#login")!,
            version: "1",
            chainId: 1,
            nonce: "qWeRtY123456",
            issuedAt: Date(timeIntervalSince1970: 1_655_082_630.023),
            expirationTime: nil,
            notBefore: nil,
            requestId: nil,
            resources: nil
        )

        XCTAssertNoThrow(try message.validate())

        message.nonce = "qwerty"

        XCTAssertThrowsError(try message.validate())

        message.nonce = "qwerty123$#@"

        XCTAssertThrowsError(try message.validate())
    }

    func testRequestIdValidation() {
        var message = try! SiweMessage(
            domain: "login.xyz",
            address: "0x9d8A62f656a8d1615C1294fd71e9CFb3E4855A4F",
            statement: nil,
            uri: URL(string: "https://login.xyz/demo#login")!,
            version: "1",
            chainId: 1,
            nonce: "qWeRtY123456",
            issuedAt: Date(timeIntervalSince1970: 1_655_082_630.023),
            expirationTime: nil,
            notBefore: nil,
            requestId: "some-request-id",
            resources: nil
        )

        XCTAssertNoThrow(try message.validate())

        message.requestId = ""

        XCTAssertThrowsError(try message.validate())
    }
}

private extension Data {
    func asJson(with writingOptions: JSONSerialization.WritingOptions) -> Data {
        guard
            let object = try? JSONSerialization.jsonObject(with: self, options: []),
            let data = try? JSONSerialization.data(withJSONObject: object, options: writingOptions)
        else { return self }
        return data
    }
}
