//
//  ENSOffchainTests.swift
//  web3sTests
//
//  Created by Miguel on 17/05/2022.
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import XCTest
@testable import web3

class ENSOffchainTests: XCTestCase {
    var account: EthereumAccount?
    var client: EthereumClient!

    override func setUp() {
        super.setUp()
        self.client = EthereumClient(url: URL(string: TestConfig.clientUrl)!)
    }

    func testDNSEncode() {
        XCTAssertEqual(
            EthereumNameService.dnsEncode(name: "offchainexample.eth").web3.hexString,
            "0x0f6f6666636861696e6578616d706c650365746800"
            )
        XCTAssertEqual(
            EthereumNameService.dnsEncode(name: "1.offchainexample.eth").web3.hexString,
            "0x01310f6f6666636861696e6578616d706c650365746800"
            )

    }

    func testGivenRopstenRegistry_WhenResolvingOffchainENS_ResolvesCorrectly() async {
        do {
            let nameService = EthereumNameService(client: client!)
            let ens = try await nameService.resolve(
                ens: "offchainexample.eth",
                mode: .allowOffchainLookup
            )
            XCTAssertEqual(EthereumAddress("0xd8da6bf26964af9d7eed9e03e53415d37aa96045"), ens)
        } catch {
            XCTFail("Expected ens but failed \(error).")
        }
    }

    func testGivenRopstenRegistry_WhenResolvingOffchainENSAndDisabled_ThenFails() async {
        do {
            let nameService = EthereumNameService(client: client!)
            let _ = try await nameService.resolve(
                ens: "offchainexample.eth",
                mode: .onchain
            )
            XCTFail("Expecting error")
        } catch let error {
            XCTAssertEqual(error as? EthereumNameServiceError, .ensUnknown)
        }
    }

    func testGivenRopstenRegistry_WhenResolvingNonOffchainENS_ThenResolves() async {
        do {
            let nameService = EthereumNameService(client: client!)
            let ens = try await nameService.resolve(
                ens: "resolver.eth",
                mode: .allowOffchainLookup
            )
            XCTAssertEqual(EthereumAddress("0x42d63ae25990889e35f215bc95884039ba354115"), ens)
        } catch {
            XCTFail("Expected ens but failed \(error).")
        }
    }
}

