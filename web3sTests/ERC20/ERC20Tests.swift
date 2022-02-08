//
//  ERC20Tests.swift
//  web3swiftTests
//
//  Created by Matt Marshall on 13/04/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import XCTest
import BigInt
@testable import web3

class ERC20Tests: XCTestCase {
    var client: EthereumClient?
    var erc20: ERC20?
    let testContractAddress = EthereumAddress(TestConfig.erc20Contract)

    override func setUp() {
        super.setUp()
        self.client = EthereumClient(url: URL(string: TestConfig.clientUrl)!)
        self.erc20 = ERC20(client: client!)
    }

    override func tearDown() {
        super.tearDown()
    }

    func testName() {
        let expect = expectation(description: "Get token name")
        erc20?.name(tokenContract: self.testContractAddress, completion: { (error, name) in
            XCTAssertNil(error)
            XCTAssertEqual(name, "BokkyPooBah Test Token")
            expect.fulfill()
        })
        waitForExpectations(timeout: 10)
    }

    func testNonZeroDecimals() {
        let expect = expectation(description: "Get token decimals")
        erc20?.decimals(tokenContract: self.testContractAddress, completion: { (error, decimals) in
            XCTAssertNil(error)
            XCTAssertEqual(decimals, 18)
            expect.fulfill()
        })
        waitForExpectations(timeout: 10)
    }

    func testZeroDecimals() {
        let expect = expectation(description: "Get token decimals (0)")
        erc20?.decimals(tokenContract: EthereumAddress("0x40dd3ac2481960cf34d96e647dd0bc52a1f03f52"), completion: { (error, decimals) in
            XCTAssertNil(error)
            XCTAssertEqual(decimals, 0)
            expect.fulfill()
        })
        waitForExpectations(timeout: 10)
    }

    func testSymbol() {
        let expect = expectation(description: "Get token symbol")
        erc20?.symbol(tokenContract: self.testContractAddress, completion: { (error, symbol) in
            XCTAssertNil(error)
            XCTAssertEqual(symbol, "BOKKY")
            expect.fulfill()
        })
        waitForExpectations(timeout: 10)
    }

    func testTransferRawEvent() {
        let expect = expectation(description: "Get transfer event")

        let result = try! ABIEncoder.encode(EthereumAddress("0x72e3b687805ef66bf2a1e6d9f03faf8b33f0267a"))
        let sig = try! ERC20Events.Transfer.signature()
        let topics = [ sig, result.hexString]

        self.client?.getEvents(addresses: nil, topics: topics, fromBlock: .Earliest, toBlock: .Latest, eventTypes: [ERC20Events.Transfer.self], completion: { (error, events, unprocessed) in
            XCTAssert(events.count > 0)
            expect.fulfill()
        })
        waitForExpectations(timeout: 10)
    }

    func testGivenAddressWithInTransfers_ThenGetsTheTransferEvents() {
        let expect = expectation(description: "Get transfer events to")

        erc20?.transferEventsTo(recipient: EthereumAddress("0x72e3b687805ef66bf2a1e6d9f03faf8b33f0267a"), fromBlock: .Earliest, toBlock: .Latest, completion: { (error, events) in
            XCTAssert(events!.count > 0)
            expect.fulfill()
        })

        waitForExpectations(timeout: 10)
    }

    func testGivenAddressWithoutInTransfers_ThenGetsNoTransferEvents() {
        let expect = expectation(description: "Get transfer events to")

        erc20?.transferEventsTo(recipient: EthereumAddress("0x78eac6878f5ef99bf2b12698f03faf8b33f02676"), fromBlock: .Earliest, toBlock: .Latest, completion: { (error, events) in
            XCTAssertEqual(events?.count, 0)
            expect.fulfill()
        })

        waitForExpectations(timeout: 10)
    }


    func testGivenAddressWithOutgoingEvents_ThenGetsTheTransferEvents() {
        let expect = expectation(description: "Get transfer events to")

        erc20?.transferEventsFrom(sender: EthereumAddress("0x2FB78FA9842f20bfD515A41C3196C4b368bDbC48"), fromBlock: .Earliest, toBlock: .Latest, completion: { (error, events) in
            XCTAssertEqual(events?.first?.log.transactionHash, "0xfb6e0d7fdf8f9b97fe9b634cb5abc7041ee47a396191f23425955f9fda008efe")
            XCTAssertEqual(events?.first?.to, EthereumAddress("0xFe325C1E3396b2285d517B0CE2E3ffA472260Bce"))
            XCTAssertEqual(events?.first?.value, BigUInt(10).power(18))
            XCTAssertEqual(events?.first?.log.address, EthereumAddress("0xdb0040451f373949a4be60dcd7b6b8d6e42658b6"))
            expect.fulfill()
        })

        waitForExpectations(timeout: 10)
    }

    func testGivenAddressWithoutOutgoingEvents_ThenGetsTheTransferEvents() {
        let expect = expectation(description: "Get transfer events to")

        erc20?.transferEventsFrom(sender: EthereumAddress("0x78eac6878f5ef99bf2b12698f03faf8b33f02676"), fromBlock: .Earliest, toBlock: .Latest, completion: { (error, events) in
            XCTAssertEqual(events?.count, 0)
            expect.fulfill()
        })

        waitForExpectations(timeout: 10)
    }

}

#if compiler(>=5.5) && canImport(_Concurrency)

@available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
extension ERC20Tests {
    func testName_Async() async {
        do {
            let name = try await erc20?.name(tokenContract: self.testContractAddress)
            XCTAssertEqual(name, "BokkyPooBah Test Token")
        } catch {
            XCTFail("Expected name but failed \(error).")
        }
    }

    func testNonZeroDecimals_Async() async {
        do {
            let decimals = try await erc20?.decimals(tokenContract: self.testContractAddress)
            XCTAssertEqual(decimals, 18)
        } catch {
            XCTFail("Expected decimals but failed \(error).")
        }
    }

    func testZeroDecimals_Async() async {
        do {
            let decimals = try await erc20?.decimals(tokenContract: EthereumAddress("0x40dd3ac2481960cf34d96e647dd0bc52a1f03f52"))
            XCTAssertEqual(decimals, 0)
        } catch {
            XCTFail("Expected decimals but failed \(error).")
        }
    }

    func testSymbol_Async() async {
        do {
            let symbol = try await erc20?.symbol(tokenContract: self.testContractAddress)
            XCTAssertEqual(symbol, "BOKKY")
        } catch {
            XCTFail("Expected symbol but failed \(error).")
        }
    }

    func testTransferRawEvent_Async() async {
        do {
            let result = try! ABIEncoder.encode(EthereumAddress("0x72e3b687805ef66bf2a1e6d9f03faf8b33f0267a"))
            let sig = try! ERC20Events.Transfer.signature()
            let topics = [ sig, result.hexString]

            let eventResults = try await self.client?.getEvents(addresses: nil, topics: topics, fromBlock: .Earliest, toBlock: .Latest, eventTypes: [ERC20Events.Transfer.self])
            XCTAssert(eventResults!.events.count > 0)
        } catch {
            XCTFail("Expected eventResults but failed \(error).")
        }
    }

    func testGivenAddressWithInTransfers_ThenGetsTheTransferEvents_Async() async {
        do {
            let events = try await erc20?.transferEventsTo(recipient: EthereumAddress("0x72e3b687805ef66bf2a1e6d9f03faf8b33f0267a"), fromBlock: .Earliest, toBlock: .Latest)
            XCTAssert(events!.count > 0)
        } catch {
            XCTFail("Expected events but failed \(error).")
        }
    }

    func testGivenAddressWithoutInTransfers_ThenGetsNoTransferEvents_Async() async {
        do {
            let events = try await erc20?.transferEventsTo(recipient: EthereumAddress("0x78eac6878f5ef99bf2b12698f03faf8b33f02676"), fromBlock: .Earliest, toBlock: .Latest)
            XCTAssertEqual(events?.count, 0)
        } catch {
            XCTFail("Expected events but failed \(error).")
        }
    }


    func testGivenAddressWithOutgoingEvents_ThenGetsTheTransferEvents_Async() async {
        do {
            let events = try await erc20?.transferEventsFrom(sender: EthereumAddress("0x2FB78FA9842f20bfD515A41C3196C4b368bDbC48"), fromBlock: .Earliest, toBlock: .Latest)
            XCTAssertEqual(events?.first?.log.transactionHash, "0xfb6e0d7fdf8f9b97fe9b634cb5abc7041ee47a396191f23425955f9fda008efe")
            XCTAssertEqual(events?.first?.to, EthereumAddress("0xFe325C1E3396b2285d517B0CE2E3ffA472260Bce"))
            XCTAssertEqual(events?.first?.value, BigUInt(10).power(18))
            XCTAssertEqual(events?.first?.log.address, EthereumAddress("0xdb0040451f373949a4be60dcd7b6b8d6e42658b6"))
        } catch {
            XCTFail("Expected events but failed \(error).")
        }
    }

    func testGivenAddressWithoutOutgoingEvents_ThenGetsTheTransferEvents_Async() async {
        do {
            let events = try await erc20?.transferEventsFrom(sender: EthereumAddress("0x78eac6878f5ef99bf2b12698f03faf8b33f02676"), fromBlock: .Earliest, toBlock: .Latest)
            XCTAssertEqual(events?.count, 0)
        } catch {
            XCTFail("Expected events but failed \(error).")
        }
    }
}

#endif
