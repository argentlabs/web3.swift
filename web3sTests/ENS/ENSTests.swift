//
//  ENSTests.swift
//  web3sTests
//
//  Created by Matt Marshall on 13/03/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import XCTest
@testable import web3

class ENSTests: XCTestCase {
    var account: EthereumAccount?
    var client: EthereumClient!

    override func setUp() {
        super.setUp()
        self.client = EthereumClient(url: URL(string: TestConfig.clientUrl)!)
    }
    
    func testGivenName_ThenResolvesNameHash() {
        let name = "argent.test"
        let nameHash = EthereumNameService.nameHash(name: name)
        XCTAssertEqual(nameHash, "0x3e58ef7a2e196baf0b9d36a65cc590ac9edafb3395b7cdeb8f39206049b4534c")
    }
    
    func testGivenRopstenRegistry_WhenExistingDomainName_ResolvesOwnerAddressCorrectly() async throws {
        let function = ENSContracts.ENSRegistryFunctions.owner(contract: ENSContracts.RopstenAddress, _node: EthereumNameService.nameHash(name: "test").web3.hexData ?? Data())
        let tx = try function.transaction()
        let dataStr = try await client!.eth_call(tx, block: .latest)
        let owner = String(dataStr[dataStr.index(dataStr.endIndex, offsetBy: -40)...])
        XCTAssertEqual(owner.web3.noHexPrefix,"09b5bd82f3351a4c8437fc6d7772a9e6cd5d25a1")
    }
    
    func testGivenRopstenRegistry_WhenExistingAddress_ThenResolvesCorrectly() async throws {
        let nameService = EthereumNameService(client: client!)
        let ens = try await nameService.resolve(address: EthereumAddress("0xb0b874220ff95d62a676f58d186c832b3e6529c8"))
        XCTAssertEqual("julien.argent.test", ens)
    }
    
    func testGivenRopstenRegistry_WhenNotExistingAddress_ThenFailsCorrectly() async {
        do {
            let nameService = EthereumNameService(client: client!)
            _ = try await nameService.resolve(address: EthereumAddress("0xb0b874220ff95d62a676f58d186c832b3e6529c9"))
        } catch {
            XCTAssertEqual(error as? Web3Error, Web3Error.ensUnknown)
        }
    }
    
    func testGivenCustomRegistry_WhenNotExistingAddress_ThenResolvesFailsCorrectly() async {
        do {
            let nameService = EthereumNameService(client: client!, registryAddress: EthereumAddress("0x7D7C04B7A05539a92541105806e0971E45969F85"))
            _ = try await nameService.resolve(address: EthereumAddress("0xb0b874220ff95d62a676f58d186c832b3e6529c9"))
        } catch {
            XCTAssertEqual(error as? Web3Error, Web3Error.ensUnknown)
        }
    }
    
    func testGivenRopstenRegistry_WhenExistingENS_ThenResolvesAddressCorrectly() async throws {
        let nameService = EthereumNameService(client: client!)
        let ens = try await nameService.resolve(ens: "julien.argent.test")
        XCTAssertEqual(EthereumAddress("0xb0b874220ff95d62a676f58d186c832b3e6529c8"), ens)
    }
    
    func testGivenRopstenRegistry_WhenInvalidENS_ThenErrorsRequest() async {
        do {
            let nameService = EthereumNameService(client: client!)
            _ = try await nameService.resolve(ens: "**somegarbage)_!!")
        } catch {
            XCTAssertEqual(error as? Web3Error, Web3Error.ensUnknown)
        }
    }
    
    func testGivenCustomRegistry_WhenInvalidENS_ThenErrorsRequest() async {
        do {
            let nameService = EthereumNameService(client: client!, registryAddress: EthereumAddress("0x7D7C04B7A05539a92541105806e0971E45969F85"))
            _ = try await nameService.resolve(ens: "**somegarbage)_!!")
        } catch {
            XCTAssertEqual(error as? Web3Error, Web3Error.ensUnknown)
        }
    }

    func testGivenRopstenRegistry_ThenResolvesMultipleAddressesInOneCall() async throws {
        let nameService = EthereumNameService(client: client!)
        let results = try await nameService.resolve(addresses: [
            EthereumAddress("0xb0b874220ff95d62a676f58d186c832b3e6529c8"),
            EthereumAddress("0x09b5bd82f3351a4c8437fc6d7772a9e6cd5d25a1"),
            EthereumAddress("0x7e691d7ffb007abe91d8a24d7f22fc74307dab06")
        ]).map { $0.output }

        XCTAssertEqual(
            results,
            [
                .resolved("julien.argent.test"),
                .couldNotBeResolved(.ensUnknown),
                .resolved("davidtests.argent.xyz")
            ]
        )
    }

    func testGivenRopstenRegistry_ThenResolvesMultipleNamesInOneCall() async throws {

        let nameService = EthereumNameService(client: client!)
        let results = try await nameService.resolve(names: [
            "julien.argent.test",
            "davidtests.argent.xyz",
            "somefakeens.argent.xyz",
        ]).map { $0.output }
        
        XCTAssertEqual(
            results,
            [
                .resolved(EthereumAddress("0xb0b874220ff95d62a676f58d186c832b3e6529c8")),
                .resolved(EthereumAddress("0x7e691d7ffb007abe91d8a24d7f22fc74307dab06")),
                .couldNotBeResolved(.ensUnknown)
            ]
        )
    }
}
