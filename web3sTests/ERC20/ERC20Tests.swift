//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import BigInt
import XCTest
@testable import web3

class ERC20Tests: XCTestCase {
    var client: EthereumClientProtocol?
    var erc20: ERC20?
    let testContractAddress = EthereumAddress(TestConfig.erc20Contract)

    override func setUp() {
        super.setUp()
        client = EthereumHttpClient(url: URL(string: TestConfig.clientUrl)!, network: TestConfig.network)
        erc20 = ERC20(client: client!)
    }

    override func tearDown() {
        super.tearDown()
    }

    func testName() async {
        do {
            let name = try await erc20?.name(tokenContract: testContractAddress)
            XCTAssertEqual(name, "USD Coin")
        } catch {
            XCTFail("Expected name but failed \(error).")
        }
    }

    func testNonZeroDecimals() async {
        do {
            let decimals = try await erc20?.decimals(tokenContract: testContractAddress)
            XCTAssertEqual(decimals, 6)
        } catch {
            XCTFail("Expected decimals but failed \(error).")
        }
    }

    func testNoDecimals() async {
        do {
            let decimals = try await erc20?.decimals(tokenContract: "0x40dd3ac2481960cf34d96e647dd0bc52a1f03f52")
            XCTAssertEqual(decimals, 0)
        } catch {
            XCTFail("Expected decimals but failed \(error).")
        }
    }

    func testSymbol() async {
        do {
            let symbol = try await erc20?.symbol(tokenContract: testContractAddress)
            XCTAssertEqual(symbol, "USDC")
        } catch {
            XCTFail("Expected symbol but failed \(error).")
        }
    }

    func testTransferRawEvent() async {
        do {
            let result = try! ABIEncoder.encode(EthereumAddress("0x162142f0508F557C02bEB7C473682D7C91Bcef41"))
            let sig = try! ERC20Events.Transfer.signature()
            let topics = [ sig, result.hexString]

            let eventResults = try await client?.getEvents(addresses: nil, topics: topics, fromBlock: .Earliest, toBlock: .Latest, eventTypes: [ERC20Events.Transfer.self])
            XCTAssert(eventResults!.events.count > 0)
        } catch {
            XCTFail("Expected eventResults but failed \(error).")
        }
    }

    func testGivenAddressWithInTransfers_ThenGetsTheTransferEvents() async {
        do {
            let events = try await erc20?.transferEventsTo(recipient: "0x162142f0508F557C02bEB7C473682D7C91Bcef41", fromBlock: .Earliest, toBlock: .Latest)
            XCTAssert(events!.count > 0)
        } catch {
            XCTFail("Expected events but failed \(error).")
        }
    }

    func testGivenAddressWithoutInTransfers_ThenGetsNoTransferEvents() async {
        do {
            let events = try await erc20?.transferEventsTo(recipient: "0x78eac6878f5ef99bf2b12698f03faf8b33f02676", fromBlock: .Earliest, toBlock: .Latest)
            XCTAssertEqual(events?.count, 0)
        } catch {
            XCTFail("Expected events but failed \(error).")
        }
    }

    func testGivenAddressWithOutgoingEvents_ThenGetsTheTransferEvents() async {
        do {
            let events = try await erc20?.transferEventsFrom(sender: "0x64d0eA4FC60f27E74f1a70Aa6f39D403bBe56793", fromBlock: .Earliest, toBlock: .Latest)
            XCTAssertEqual(events?.first?.log.transactionHash, "0x9bf24689047a2af63aed77da170410df3c14762ebf4bd6d37acfb1cf968b7d32")
            XCTAssertEqual(events?.first?.to, EthereumAddress("0x162142f0508F557C02bEB7C473682D7C91Bcef41"))
            XCTAssertEqual(events?.first?.value, 10000000)
            XCTAssertEqual(events?.first?.log.address, EthereumAddress(TestConfig.erc20Contract))
        } catch {
            XCTFail("Expected events but failed \(error).")
        }
    }

    func testGivenAddressWithoutOutgoingEvents_ThenGetsTheTransferEvents() async {
        do {
            let events = try await erc20?.transferEventsFrom(sender: "0x78eac6878f5ef99bf2b12698f03faf8b33f02676", fromBlock: .Earliest, toBlock: .Latest)
            XCTAssertEqual(events?.count, 0)
        } catch {
            XCTFail("Expected events but failed \(error).")
        }
    }
}

class ERC20WebSocketTests: ERC20Tests {
    override func setUp() {
        super.setUp()
        client = EthereumWebSocketClient(url: URL(string: TestConfig.wssUrl)!, configuration: TestConfig.webSocketConfig, network: TestConfig.network)
    }
}
