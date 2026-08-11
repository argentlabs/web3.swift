//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import XCTest
@testable import web3

final class Box<T>: @unchecked Sendable {
    var value: T
    
    init(_ value: T) {
        self.value = value
    }
}

class MulticallTests: XCTestCase, @unchecked Sendable {
    var client: EthereumClientProtocol!
    var multicall: Multicall!
    let testContractAddress = EthereumAddress(TestConfig.erc20Contract)

    override func setUp() {
        super.setUp()
        client = TestConfig.makeClient(url: TestConfig.clientUrl, network: TestConfig.network)
        multicall = Multicall(client: client!)
    }

    func testNameAndSymbol() async throws {
        var aggregator = Multicall.Aggregator()

        let nameBox = Box<String?>(nil)
        let decimalsBox = Box<UInt8?>(nil)

        try aggregator.append(ERC20Functions.decimals(contract: testContractAddress)) { output in
            decimalsBox.value = try ERC20Responses.decimalsResponse(data: output.get())?.value
        }

        try aggregator.append(
            function: ERC20Functions.name(contract: testContractAddress),
            response: ERC20Responses.nameResponse.self
        ) { result in
            nameBox.value = try? result.get()
        }

        try aggregator.append(ERC20Functions.symbol(contract: testContractAddress))

        do {
            let response = try await multicall.aggregate(calls: aggregator.calls)
            let symbol = try ERC20Responses.symbolResponse(data: try response.outputs[2].get())?.value
            XCTAssertEqual(symbol, "USDC")
        } catch {
            XCTFail("Unexpected failure while handling output")
        }

        XCTAssertEqual(decimalsBox.value, 6)
        XCTAssertEqual(nameBox.value, "USD Coin")
    }
    
    func testNameAndSymbolMulticall2() async throws {
        var aggregator = Multicall.Aggregator()

        let nameBox = Box<String?>(nil)
        let decimalsBox = Box<UInt8?>(nil)

        try aggregator.append(ERC20Functions.decimals(contract: testContractAddress)) { output in
            decimalsBox.value = try ERC20Responses.decimalsResponse(data: output.get())?.value
        }

        try aggregator.append(
            function: ERC20Functions.name(contract: testContractAddress),
            response: ERC20Responses.nameResponse.self
        ) { result in
            nameBox.value = try? result.get()
        }

        try aggregator.append(ERC20Functions.symbol(contract: testContractAddress))

        do {
            let response = try await multicall.tryAggregate(requireSuccess: true, calls: aggregator.calls)
            let decoded = try response.outputs.last?.get()
            let symbol = try ERC20Responses.symbolResponse(data: decoded ?? "")?.value
            XCTAssertEqual(symbol, "USDC")
        } catch {
            XCTFail("Unexpected failure while handling output")
        }

        XCTAssertEqual(decimalsBox.value, 6)
        XCTAssertEqual(nameBox.value, "USD Coin")
    }
}

class MulticallWebSocketTests: MulticallTests, @unchecked Sendable {
    override func setUpWithError() throws {
        try skipUnlessWebSocketTestsEnabled()
        try super.setUpWithError()
    }

    override func setUp() {
        super.setUp()
        client = EthereumWebSocketClient(url: URL(string: TestConfig.wssUrl)!, configuration: TestConfig.webSocketConfig, network: TestConfig.network)
    }
}
