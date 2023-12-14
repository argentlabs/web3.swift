//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import XCTest
@testable import web3

class ENSTests: XCTestCase {
    var account: EthereumAccount?
    var client: EthereumClientProtocol!
    var mainnetClient: EthereumClientProtocol!

    override func setUp() {
        super.setUp()
        client = EthereumHttpClient(url: URL(string: TestConfig.clientUrl)!, network: .sepolia)
        mainnetClient = EthereumHttpClient(url: URL(string: TestConfig.mainnetUrl)!, network: .mainnet)
    }

    func testGivenName_ThenResolvesNameHash() {
        let name = "argent.test"
        let nameHash = EthereumNameService.nameHash(name: name)
        XCTAssertEqual(nameHash, "0x3e58ef7a2e196baf0b9d36a65cc590ac9edafb3395b7cdeb8f39206049b4534c")
    }

    func testGivenRegistry_WhenExistingDomainName_ResolvesOwnerAddressCorrectly() async {
        do {
            let function = ENSContracts.ENSRegistryFunctions.owner(contract: ENSContracts.RegistryAddress, _node: EthereumNameService.nameHash(name: "eth").web3.hexData ?? Data())

            let tx = try function.transaction()

            let dataStr = try await client?.eth_call(tx, resolution: .noOffchain(failOnExecutionError: true), block: .Latest)
            guard let dataStr = dataStr else {
                XCTFail()
                return
            }

            let owner = String(dataStr[dataStr.index(dataStr.endIndex, offsetBy: -40)...])
            XCTAssertEqual(owner.web3.noHexPrefix, "57f1887a8bf19b14fc0df6fd9b2acc9af147ea85")
        } catch {
            XCTFail("Expected dataStr but failed \(error).")
        }
    }

    func testGivenRegistry_WhenExistingAddress_ThenResolvesCorrectly() async {
        do {
            let nameService = EthereumNameService(client: client!)
            let ens = try await nameService.resolve(
                address: "0x162142f0508F557C02bEB7C473682D7C91Bcef41",
                mode: .onchain
            )
            XCTAssertEqual("darhmike.eth", ens)
        } catch {
            XCTFail("Expected ens but failed \(error).")
        }
    }

    func testGivenRegistry_WhenExistingAddressHasSubdomain_ThenResolvesCorrectly() async {
        do {
            let nameService = EthereumNameService(client: client!)
            let ens = try await nameService.resolve(
                address: "0xB1037eB3268f942715c999EA6697ce33Febd70A7",
                mode: .onchain
            )
            XCTAssertEqual("subdomain.darhmike.eth", ens)
        } catch {
            XCTFail("Expected ens but failed \(error).")
        }
    }

    func testGivenRegistry_WhenAddressHasSubdomain_AndReverseRecordNotSet_ThenDoesNotResolveCorrectly() async {
        do {
            let nameService = EthereumNameService(client: client!)
            let _ = try await nameService.resolve(
                address: "0x787411394Ccb38483a6F303FDee075f3EA67D65F",
                mode: .onchain
            )
            XCTFail("Resolved but expected failure")
        } catch {
            XCTAssertEqual(error as? EthereumNameServiceError, .ensUnknown)
        }
    }

    func testGivenRegistry_WhenAddressHasSubdomain_AndReverseRecordNotSet_ThenResolvesENS() async {
        do {
            let nameService = EthereumNameService(client: client!)
            let address = try await nameService.resolve(
                ens: "another.darhmike.eth",
                mode: .onchain
            )
            XCTAssertEqual(address, "0xa25093F94ffBdb975B81474D63D244dE6898eC3B")
        } catch {
            XCTAssertEqual(error as? EthereumNameServiceError, .ensUnknown)
        }
    }

    func testGivenRegistry_WhenNotExistingAddress_ThenFailsCorrectly() async {
        do {
            let nameService = EthereumNameService(client: client!)
            _ = try await nameService.resolve(
                address: "0xb0b874220ff95d62a676f58d186c832b3e6529c9",
                mode: .onchain
            )
            XCTFail("Expected to throw while awaiting, but succeeded")
        } catch {
            XCTAssertEqual(error as? EthereumNameServiceError, .ensUnknown)
        }
    }

    func testGivenRegistry_WhenExistingENS_ThenResolvesAddressCorrectly() async {
        do {
            let nameService = EthereumNameService(client: client!)
            let ens = try await nameService.resolve(
                ens: "darhmike.eth",
                mode: .onchain
            )
            XCTAssertEqual(EthereumAddress("0x162142f0508F557C02bEB7C473682D7C91Bcef41"), ens)
        } catch {
            XCTFail("Expected ens but failed \(error).")
        }
    }

    func testGivenRegistry_WhenInvalidENS_ThenErrorsRequest() async {
        do {
            let nameService = EthereumNameService(client: client!)
            _ = try await nameService.resolve(
                ens: "**somegarbage)_!!",
                mode: .onchain
            )
            XCTFail("Expected to throw while awaiting, but succeeded")
        } catch {
            XCTAssertEqual(error as? EthereumNameServiceError, .ensUnknown)
        }
    }

    func testGivenRegistry_ThenResolvesMultipleAddressesWithMultiCall() async {
        do {
            let nameService = EthereumNameService(client: client!)

            var results: [EthereumNameService.ResolveOutput<String>]?

            let resolutions = try await nameService.resolve(addresses: [
                "0x162142f0508F557C02bEB7C473682D7C91Bcef41",
                "0x09b5bd82f3351a4c8437fc6d7772a9e6cd5d25a1",
                "0x64d0eA4FC60f27E74f1a70Aa6f39D403bBe56793"
            ])

            results = resolutions.map { $0.output }

            XCTAssertEqual(
                results,
                [
                    .resolved("darhmike.eth"),
                    .couldNotBeResolved(.ensUnknown),
                    .resolved("darthmike.eth")
                ]
            ) } catch {
                XCTFail("Expected resolutions but failed \(error).")
            }
    }

    func testGivenRegistry_ThenResolvesSingleAddressWithMultiCall() async {
        do {
            let nameService = EthereumNameService(client: client!)

            var results: [EthereumNameService.ResolveOutput<String>]?

            let resolutions = try await nameService.resolve(addresses: [
                "0x162142f0508F557C02bEB7C473682D7C91Bcef41"
            ])

            results = resolutions.map { $0.output }

            XCTAssertEqual(
                results,
                [
                    .resolved("darhmike.eth")
                ]
            ) } catch {
                XCTFail("Expected resolutions but failed \(error).")
            }
    }

    func testGivenRegistry_WhenAddressHasSubdomain_ThenResolvesSingleAddressWithMultiCall() async {
        do {
            let nameService = EthereumNameService(client: client!)

            var results: [EthereumNameService.ResolveOutput<String>]?

            let resolutions = try await nameService.resolve(addresses: [
                "0xB1037eB3268f942715c999EA6697ce33Febd70A7"
            ])

            results = resolutions.map { $0.output }

            XCTAssertEqual(
                results,
                [
                    .resolved("subdomain.darhmike.eth")
                ]
            ) } catch {
                XCTFail("Expected resolutions but failed \(error).")
            }
    }

    func testGivenRegistry_WhenAddressHasSubdomain_AndReverseRecordNotSet_ThenDoesNotResolveSingleAddressWithMultiCall() async {
        do {
            let nameService = EthereumNameService(client: client!)

            var results: [EthereumNameService.ResolveOutput<String>]?

            let resolutions = try await nameService.resolve(addresses: [
                "0x787411394Ccb38483a6F303FDee075f3EA67D65F"
            ])

            results = resolutions.map { $0.output }

            XCTAssertEqual(
                results,
                [
                    .couldNotBeResolved(.ensUnknown)
                ]
            ) } catch {
                XCTFail("Expected resolutions but failed \(error).")
            }
    }

    func testGivenRegistry_WhenAddressHasSubdomain_AndReverseRecordNotSet_ThenResolvesENSWithMultiCall() async {
        do {
            let nameService = EthereumNameService(client: client!)
            let results = try await nameService.resolve(
                names: ["another.darhmike.eth"]
            )
            XCTAssertEqual(
                results.map(\.output),
                [
                    .resolved("0xa25093F94ffBdb975B81474D63D244dE6898eC3B")
                ]
            )
        } catch {
            XCTAssertEqual(error as? EthereumNameServiceError, .ensUnknown)
        }
    }

    func testGivenRegistry_ThenResolvesMultipleNamesWithMultiCall() async {
        do {
            let nameService = EthereumNameService(client: client!)

            var results: [EthereumNameService.ResolveOutput<EthereumAddress>]?

            let resolutions = try await nameService.resolve(names: [
                "darhmike.eth",
                "darthmike.eth",
                "somefakeens.argent.xyz"
            ])

            results = resolutions.map { $0.output }

            XCTAssertEqual(
                results,
                [
                    .resolved("0x162142f0508F557C02bEB7C473682D7C91Bcef41"),
                    .resolved("0x64d0eA4FC60f27E74f1a70Aa6f39D403bBe56793"),
                    .couldNotBeResolved(.ensUnknown)
                ]
            )
        } catch {
            XCTFail("Expected resolutions but failed \(error).")
        }
    }

    // TODO [Tests] Temporarily removed until set up for offchain ENS is done
//    func testGivenMainnetRegistry_WhenWildcardSupported_AndAddressHasSubdomain_ThenResolvesExampleCorrectly() async {
//        do {
//            let nameService = EthereumNameService(client: client!)
//
//            let address = try await nameService.resolve(
//                ens: "ricmoose.hatch.eth",
//                mode: .onchain
//            )
//
//            XCTAssertEqual(address, EthereumAddress("0x4b711a377b1b3534749fbe5e59bcf7f94d92ea98"))
//        } catch {
//            XCTFail("Expected ens but failed \(error).")
//        }
//    }

    func testGivenRegistry_WhenWildcardNOTSupported_AndAddressHasSubdomain_ThenFailsResolving() async {
        do {
            let nameService = EthereumNameService(client: client!)

            _ = try await nameService.resolve(
                ens: "1.resolver.eth",
                mode: .onchain
            )

            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(error as? EthereumNameServiceError, .ensUnknown)
        }
    }

    func testGivenMainnetRegistry_WhenResolvingOnChain_ItResolvesName() async {
        do {
            let nameService = EthereumNameService(client: mainnetClient!)

            let address = try await nameService.resolve(
                ens: "michael-brown.eth",
                mode: .onchain
            )

            XCTAssertEqual("0x7bcf6af56f0e4e7498b2a76d4ac8b3262ac790bb", address)
        } catch {
            XCTFail("Error \(error)")
        }
    }

    func testGivenMainnetRegistry_WhenAllowsOffchain_AndDomainDoesNotHaveOffchain_ItResolvesName() async {
        do {
            let nameService = EthereumNameService(client: mainnetClient!)

            let address = try await nameService.resolve(
                ens: "michael-brown.eth",
                mode: .allowOffchainLookup
            )

            XCTAssertEqual("0x7bcf6af56f0e4e7498b2a76d4ac8b3262ac790bb", address)
        } catch {
            XCTFail("Error \(error)")
        }
    }

    func testGivenMainnetRegistry_WhenResolvingOnChain_ItResolvesAddress() async {
        do {
            let nameService = EthereumNameService(client: mainnetClient!)

            let name = try await nameService.resolve(
                address: "0x7bcf6af56f0e4e7498b2a76d4ac8b3262ac790bb",
                mode: .onchain
            )

            XCTAssertEqual("michael-brown.eth", name)
        } catch {
            XCTFail("Error \(error)")
        }
    }

    func testGivenMainnetRegistry_WhenAllowsOffchain_ItResolvesAddress() async {
        do {
            let nameService = EthereumNameService(client: mainnetClient!)

            let name = try await nameService.resolve(
                address: "0x7bcf6af56f0e4e7498b2a76d4ac8b3262ac790bb",
                mode: .allowOffchainLookup
            )

            XCTAssertEqual("michael-brown.eth", name)
        } catch {
            XCTFail("Error \(error)")
        }
    }
}

class ENSWebSocketTests: ENSTests {
    override func setUp() {
        super.setUp()
        client = EthereumWebSocketClient(url: URL(string: TestConfig.wssUrl)!, configuration: TestConfig.webSocketConfig, network: TestConfig.network)
        mainnetClient = EthereumWebSocketClient(url: URL(string: TestConfig.wssMainnetUrl)!, configuration: TestConfig.webSocketConfig, network: .mainnet)
    }
}
