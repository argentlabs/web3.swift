//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import XCTest
@testable import web3

class ENSOffchainTests: XCTestCase {
    var account: EthereumAccount?
    var client: EthereumClientProtocol!

    override func setUp() {
        super.setUp()
        client = EthereumHttpClient(url: URL(string: TestConfig.clientUrl)!, network: TestConfig.network)
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

    // TODO [Tests] Disabled until we can test with proper offchain ENS set up
//    func testGivenRegistry_WhenResolvingOffchainENS_ResolvesCorrectly() async {
//        do {
//            let nameService = EthereumNameService(client: client!)
//            let ens = try await nameService.resolve(
//                ens: "offchainexample.eth",
//                mode: .allowOffchainLookup
//            )
//            XCTAssertEqual(EthereumAddress("0xd8da6bf26964af9d7eed9e03e53415d37aa96045"), ens)
//        } catch {
//            XCTFail("Expected ens but failed \(error).")
//        }
//    }
//
//    func testGivenRegistry_WhenResolvingOffchainENSAndDisabled_ThenFails() async {
//        do {
//            let nameService = EthereumNameService(client: client!)
//            _ = try await nameService.resolve(
//                ens: "offchainexample.eth",
//                mode: .onchain
//            )
//            XCTFail("Expecting error")
//        } catch let error {
//            XCTAssertEqual(error as? EthereumNameServiceError, .ensUnknown)
//        }
//    }
//
//    func testGivenRegistry_WhenResolvingNonOffchainENS_ThenResolves() async {
//        do {
//            let nameService = EthereumNameService(client: client!)
//            let ens = try await nameService.resolve(
//                ens: "resolver.eth",
//                mode: .allowOffchainLookup
//            )
//            XCTAssertEqual(EthereumAddress("0xd7a4f6473f32ac2af804b3686ae8f1932bc35750"), ens)
//        } catch {
//            XCTFail("Expected ens but failed \(error).")
//        }
//    }
//
//    func testGivenRegistry_WhenWildcardSupported_AndAddressHasSubdomain_ThenResolvesCorrectly() async {
//        do {
//            let nameService = EthereumNameService(client: client!)
//
//            let address = try await nameService.resolve(
//                ens: "1.offchainexample.eth",
//                mode: .allowOffchainLookup
//            )
//
//            XCTAssertEqual(address, EthereumAddress("0x41563129cdbbd0c5d3e1c86cf9563926b243834d"))
//        } catch {
//            XCTFail("Expected ens but failed \(error).")
//        }
//    }
//
//    func testGivenRegistry_WhenWildcardNOTSupported_AndAddressHasSubdomain_ThenFailsResolving() async {
//        do {
//            let nameService = EthereumNameService(client: client!)
//
//            _ = try await nameService.resolve(
//                ens: "1.resolver.eth",
//                mode: .allowOffchainLookup
//            )
//
//            XCTFail("Expected error")
//        } catch {
//            XCTAssertEqual(error as? EthereumNameServiceError, .ensUnknown)
//        }
//    }
//
//    func testGivenRegistry_WhenTwoRequestsWithAndWithoutSubdomain_ThenBothResolveCorrectly() async {
//        let nameService = EthereumNameService(client: client!)
//
//        do {
//            let ens = try await nameService.resolve(
//                ens: "resolver.eth",
//                mode: .allowOffchainLookup
//            )
//            XCTAssertEqual(EthereumAddress("0xd7a4f6473f32ac2af804b3686ae8f1932bc35750"), ens)
//        } catch {
//            XCTFail("Expected ens but failed \(error).")
//        }
//        do {
//            _ = try await nameService.resolve(
//                ens: "1.resolver.eth",
//                mode: .allowOffchainLookup
//            )
//
//            XCTFail("Expected error")
//        } catch {
//            XCTAssertEqual(error as? EthereumNameServiceError, .ensUnknown)
//        }
//    }
//
//    func testGivenRegistry_WhenTwoRequestsWithoutAndWithSubdomain_ThenBothResolveCorrectly() async {
//        let nameService = EthereumNameService(client: client!)
//
//        do {
//            _ = try await nameService.resolve(
//                ens: "1.resolver.eth",
//                mode: .allowOffchainLookup
//            )
//
//            XCTFail("Expected error")
//        } catch {
//            XCTAssertEqual(error as? EthereumNameServiceError, .ensUnknown)
//        }
//
//        do {
//            let ens = try await nameService.resolve(
//                ens: "resolver.eth",
//                mode: .allowOffchainLookup
//            )
//            XCTAssertEqual(EthereumAddress("0xd7a4f6473f32ac2af804b3686ae8f1932bc35750"), ens)
//        } catch {
//            XCTFail("Expected ens but failed \(error).")
//        }
//    }
}

class ENSOffchainWebSocketTests: ENSOffchainTests {
    override func setUp() {
        super.setUp()
        client = EthereumWebSocketClient(url: URL(string: TestConfig.wssUrl)!, configuration: TestConfig.webSocketConfig, network: TestConfig.network)
    }
}
