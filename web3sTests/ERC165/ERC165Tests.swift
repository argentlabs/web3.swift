//
//  ERC165Tests.swift
//  web3swift
//
//  Created by Miguel on 10/05/2019.
//  Copyright © 2019 Argent Labs Limited. All rights reserved.
//

import XCTest
import BigInt
@testable import web3

class ERC165Tests: XCTestCase {
    var client: EthereumClient!
    var erc165: ERC165!
    let address = EthereumAddress(TestConfig.erc165Contract)

    override func setUp() {
        super.setUp()
        self.client = EthereumClient(url: URL(string: TestConfig.clientUrl)!)
        self.erc165 = ERC165(client: client)
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
}

