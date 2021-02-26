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
    
    func testGivenRopstenRegistry_WhenExistingDomainName_ResolvesOwnerAddressCorrectly() {
        let expect = expectation(description: "Get the ENS owner")
        
        do {
            let function = ENSContracts.ENSRegistryFunctions.owner(contract: ENSContracts.RopstenAddress, _node: EthereumNameService.nameHash(name: "test").web3.hexData ?? Data())
            
            let tx = try function.transaction()
            
            client?.eth_call(tx, block: .Latest, completion: { (error, dataStr) in
                guard let dataStr = dataStr else {
                    XCTFail()
                    expect.fulfill()
                    return
                }
                let owner = String(dataStr[dataStr.index(dataStr.endIndex, offsetBy: -40)...])
                XCTAssertEqual(owner.web3.noHexPrefix,"09b5bd82f3351a4c8437fc6d7772a9e6cd5d25a1")
                expect.fulfill()
            })
            
        } catch {
            XCTFail()
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 20)
    }
    
    func testGivenRopstenRegistry_WhenExistingAddress_ThenResolvesCorrectly() {
        let expect = expectation(description: "Get the ENS address")
        
        let nameService = EthereumNameService(client: client!)
        nameService.resolve(address: EthereumAddress("0xb0b874220ff95d62a676f58d186c832b3e6529c8"), completion: { (error, ens) in
            XCTAssertEqual("julien.argent.test", ens)
            expect.fulfill()
        })
        
        waitForExpectations(timeout: 20)
    }
    
    func testGivenRopstenRegistry_WhenNotExistingAddress_ThenFailsCorrectly() {
        let expect = expectation(description: "Get the ENS address")
        
        let nameService = EthereumNameService(client: client!)
        nameService.resolve(address: EthereumAddress("0xb0b874220ff95d62a676f58d186c832b3e6529c9"), completion: { (error, ens) in
            XCTAssertNil(ens)
            XCTAssertEqual(error, .ensUnknown)
            expect.fulfill()
        })
        
        waitForExpectations(timeout: 20)
    }
    
    func testGivenCustomRegistry_WhenNotExistingAddress_ThenResolvesFailsCorrectly() {
        let expect = expectation(description: "Get the ENS address")
        
        let nameService = EthereumNameService(client: client!, registryAddress: EthereumAddress("0x7D7C04B7A05539a92541105806e0971E45969F85"))
        nameService.resolve(address: EthereumAddress("0xb0b874220ff95d62a676f58d186c832b3e6529c9"), completion: { (error, ens) in
            XCTAssertNil(ens)
            XCTAssertEqual(error, .ensUnknown)
            expect.fulfill()
        })
        
        waitForExpectations(timeout: 20)
    }
    
    func testGivenRopstenRegistry_WhenExistingENS_ThenResolvesAddressCorrectly() {
        let expect = expectation(description: "Get the ENS reverse lookup address")
        
        let nameService = EthereumNameService(client: client!)
        nameService.resolve(ens: "julien.argent.test", completion: { (error, ens) in
            XCTAssertEqual(EthereumAddress("0xb0b874220ff95d62a676f58d186c832b3e6529c8"), ens)
            expect.fulfill()
        })
        
        waitForExpectations(timeout: 20)
    }
    
    func testGivenRopstenRegistry_WhenInvalidENS_ThenErrorsRequest() {
        let expect = expectation(description: "Get the ENS reverse lookup address")
        
        let nameService = EthereumNameService(client: client!)
        nameService.resolve(ens: "**somegarbage)_!!", completion: { (error, ens) in
            XCTAssertNil(ens)
            XCTAssertEqual(error, .ensUnknown)
            expect.fulfill()
        })
        
        waitForExpectations(timeout: 20)
    }
    
    func testGivenCustomRegistry_WhenInvalidENS_ThenErrorsRequest() {
        let expect = expectation(description: "Get the ENS reverse lookup address")
        
        let nameService = EthereumNameService(client: client!, registryAddress: EthereumAddress("0x7D7C04B7A05539a92541105806e0971E45969F85"))
        nameService.resolve(ens: "**somegarbage)_!!", completion: { (error, ens) in
            XCTAssertNil(ens)
            XCTAssertEqual(error, .ensUnknown)
            expect.fulfill()
        })
        
        waitForExpectations(timeout: 20)
    }

    func testGivenRopstenRegistry_ThenResolvesMultipleAddressesInOneCall() {
        let expect = expectation(description: "Get the ENS reverse lookup address")

        let nameService = EthereumNameService(client: client!)

        var results: [EthereumNameService.ResolveOutput<String>]?

        nameService.resolve(addresses: [
            EthereumAddress("0xb0b874220ff95d62a676f58d186c832b3e6529c8"),
            EthereumAddress("0x09b5bd82f3351a4c8437fc6d7772a9e6cd5d25a1"),
            EthereumAddress("0x7e691d7ffb007abe91d8a24d7f22fc74307dab06")

        ]) { result in
            switch result {
            case .success(let resolutions):
                results = resolutions.map { $0.output }
            case .failure:
                break
            }
            expect.fulfill()
        }

        waitForExpectations(timeout: 5)

        XCTAssertEqual(
            results,
            [
                .resolved("julien.argent.test"),
                .couldNotBeResolved(.ensUnknown),
                .resolved("davidtests.argent.xyz")
            ]
        )
    }

    func testGivenRopstenRegistry_ThenResolvesMultipleNamesInOneCall() {
        let expect = expectation(description: "Get the ENS reverse lookup address")

        let nameService = EthereumNameService(client: client!)

        var results: [EthereumNameService.ResolveOutput<EthereumAddress>]?

        nameService.resolve(names: [
            "julien.argent.test",
            "davidtests.argent.xyz",
            "somefakeens.argent.xyz"

        ]) { result in
            switch result {
            case .success(let resolutions):
                results = resolutions.map { $0.output }
            case .failure:
                break
            }
            expect.fulfill()
        }

        waitForExpectations(timeout: 5)

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
