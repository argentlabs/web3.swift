//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import BigInt
import XCTest
@testable import web3

class ERC165Tests: XCTestCase {
    var client: EthereumClientProtocol!
    var erc165: ERC165!
    let address = EthereumAddress(TestConfig.erc165Contract)
    let nonSupportedAddress = EthereumAddress(TestConfig.nonerc165Contrat)

    override func setUp() {
        super.setUp()
        client = EthereumHttpClient(url: URL(string: TestConfig.clientUrl)!, network: TestConfig.network)
        erc165 = ERC165(client: client)
    }

    func test_InterfaceIDMatch() {
        XCTAssertEqual(ERC165Functions.interfaceId.web3.hexString, "0x01ffc9a7")
    }

    func test_GivenInterfaceffff_returnsNotSupported() async {
        do {
            let supported = try await erc165.supportsInterface(contract: address, id: "0xffffffff".web3.hexData!)
            XCTAssertEqual(supported, false)
        } catch {
            XCTFail("Expected supported but failed \(error).")
        }
    }

    func test_GivenInterfaceERC165_returnsSupported() async {
        do {
            let supported = try await erc165.supportsInterface(contract: address, id: ERC165Functions.interfaceId)
            XCTAssertEqual(supported, true)
        } catch {
            XCTFail("Expected supported but failed \(error).")
        }
    }

    func test_GivenContractNotImplementingERC165_WhenCalling_ReturnsNotSupported() async {
        do {
            let supported = try await erc165.supportsInterface(contract: nonSupportedAddress, id: ERC165Functions.interfaceId)
            XCTAssertEqual(supported, false)
        } catch {
            XCTFail("Expected unsupported but failed \(error).")
        }
    }
}

class ERC165WebSocketTests: ERC165Tests {
    override func setUp() {
        super.setUp()
        client = EthereumWebSocketClient(url: URL(string: TestConfig.wssUrl)!, configuration: TestConfig.webSocketConfig, network: TestConfig.network)
    }
}
