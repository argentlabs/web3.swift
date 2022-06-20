//
//  ERC1271Tests.swift
//  
//
//  Created by Rodrigo Kreutz on 15/06/22.
//

import XCTest
@testable import web3

final class ERC1271Tests: XCTestCase {
    var client: EthereumClientProtocol!
    var erc1271: ERC1271!

    override func setUp() {
        super.setUp()
        self.client = EthereumHttpClient(url: URL(string: TestConfig.clientUrl)!)
        self.erc1271 = ERC1271(client: self.client)
    }

    override func tearDown() {
        super.tearDown()
    }

    func testSuccesfulVerificationWithMagicNumberContract() async {
        do {
            let isValid = try await erc1271.isValidSignature(
                contract: EthereumAddress("0x2bD85c85666a29bD453918B20b9E5ef7603d9007"),
                messageHash: "0xb7755e72da7aca68df7d5ed5a832d027b624d56dab707d2b5257bbfc1bc5d4fd".web3.hexData!,
                signature: "0x468732fa8210c6f8481a288a668bd6f40745e67c9640f82f7415b44e7ba280e13b6fce01acaaa4ab2fe8620a179ca99960620a014fdf74d9cf828912811c1b821b".web3.hexData!
            )
            XCTAssertTrue(isValid)
        } catch {
            XCTFail("Failed with: \(error)")
        }
    }

    func testSuccessfulVerificationWithBooleanContract() async {
        do {
            let isValid = try await erc1271.isValidSignature(
                contract: EthereumAddress("0x2505E4d4A76EC941591828311159552A832681D5"),
                messageHash: "0xb7755e72da7aca68df7d5ed5a832d027b624d56dab707d2b5257bbfc1bc5d4fd".web3.hexData!,
                signature: "0x468732fa8210c6f8481a288a668bd6f40745e67c9640f82f7415b44e7ba280e13b6fce01acaaa4ab2fe8620a179ca99960620a014fdf74d9cf828912811c1b821b".web3.hexData!
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
                contract: EthereumAddress("0x2bD85c85666a29bD453918B20b9E5ef7603d9007"),
                messageHash: "0x09bf2f6417d2bc487040194b78cbdd6b04f72ea12cf0014f83f4f228bed95ee4".web3.hexData!,
                signature: "0xf85b9506180b11dc472278ff1e5fbb1e4b50baa3cadaec26b4b8179a55623f652a794c09b49227231f1144a62221453c854f09a986c1de1e19cdfff451e751b21c".web3.hexData!
            )
            XCTAssertFalse(isValid)
        } catch {
            XCTFail("Failed with: \(error)")
        }

        do {
            // Here the signature and the hash don't match
            let isValid = try await erc1271.isValidSignature(
                contract: EthereumAddress("0x2bD85c85666a29bD453918B20b9E5ef7603d9007"),
                messageHash: "0xb7755e72da7aca68df7d5ed5a832d027b624d56dab707d2b5257bbfc1bc5d4fd".web3.hexData!,
                signature: "0xf85b9506180b11dc472278ff1e5fbb1e4b50baa3cadaec26b4b8179a55623f652a794c09b49227231f1144a62221453c854f09a986c1de1e19cdfff451e751b21c".web3.hexData!
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
                contract: EthereumAddress("0x2505E4d4A76EC941591828311159552A832681D5"),
                messageHash: "0x09bf2f6417d2bc487040194b78cbdd6b04f72ea12cf0014f83f4f228bed95ee4".web3.hexData!,
                signature: "0xf85b9506180b11dc472278ff1e5fbb1e4b50baa3cadaec26b4b8179a55623f652a794c09b49227231f1144a62221453c854f09a986c1de1e19cdfff451e751b21c".web3.hexData!
            )
            XCTAssertFalse(isValid)
        } catch {
            XCTFail("Failed with: \(error)")
        }

        do {
            // Here the signature and the hash don't match
            let isValid = try await erc1271.isValidSignature(
                contract: EthereumAddress("0x2505E4d4A76EC941591828311159552A832681D5"),
                messageHash: "0xb7755e72da7aca68df7d5ed5a832d027b624d56dab707d2b5257bbfc1bc5d4fd".web3.hexData!,
                signature: "0xf85b9506180b11dc472278ff1e5fbb1e4b50baa3cadaec26b4b8179a55623f652a794c09b49227231f1144a62221453c854f09a986c1de1e19cdfff451e751b21c".web3.hexData!
            )
            XCTAssertFalse(isValid)
        } catch {
            XCTFail("Failed with: \(error)")
        }
    }
}
