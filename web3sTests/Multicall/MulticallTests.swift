//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import XCTest
@testable import web3

class MulticallTests: XCTestCase {
    var client: EthereumClientProtocol!
    var multicall: Multicall!
    let testContractAddress = EthereumAddress(TestConfig.erc20Contract)

    override func setUp() {
        super.setUp()
        client = EthereumHttpClient(url: URL(string: TestConfig.clientUrl)!)
        multicall = Multicall(client: client!)
    }

    func testNameAndSymbol() async throws {
        var aggregator = Multicall.Aggregator()

        var name: String?
        var decimals: UInt8?

        try aggregator.append(ERC20Functions.decimals(contract: testContractAddress)) { output in
            decimals = try ERC20Responses.decimalsResponse(data: output.get())?.value
        }

        try aggregator.append(
            function: ERC20Functions.name(contract: testContractAddress),
            response: ERC20Responses.nameResponse.self
        ) { result in
            name = try? result.get()
        }

        try aggregator.append(ERC20Functions.symbol(contract: testContractAddress))

        do {
            let response = try await multicall.aggregate(calls: aggregator.calls)
            let symbol = try ERC20Responses.symbolResponse(data: try response.outputs[2].get())?.value
            XCTAssertEqual(symbol, "UNI")
        } catch {
            XCTFail("Unexpected failure while handling output")
        }

        XCTAssertEqual(decimals, 18)
        XCTAssertEqual(name, "Uniswap")
    }
    
    func testNameAndSymbolMulticall2() async throws {
        var aggregator = Multicall.Aggregator()

        var name: String?
        var decimals: UInt8?

        try aggregator.append(ERC20Functions.decimals(contract: testContractAddress)) { output in
            decimals = try ERC20Responses.decimalsResponse(data: output.get())?.value
        }

        try aggregator.append(
            function: ERC20Functions.name(contract: testContractAddress),
            response: ERC20Responses.nameResponse.self
        ) { result in
            name = try? result.get()
        }

        try aggregator.append(ERC20Functions.symbol(contract: testContractAddress))

        do {
            let response = try await multicall.tryAggregate(requireSuccess: true, calls: aggregator.calls)
            let symbol = try ERC20Responses.symbolResponse(data: try response.outputs[2].get())?.value
            XCTAssertEqual(symbol, "UNI")
        } catch {
            XCTFail("Unexpected failure while handling output")
        }

        XCTAssertEqual(decimals, 18)
        XCTAssertEqual(name, "Uniswap")
    }
}

class MulticallWebSocketTests: MulticallTests {
    override func setUp() {
        super.setUp()
        client = EthereumWebSocketClient(url: URL(string: TestConfig.wssUrl)!, configuration: TestConfig.webSocketConfig)
    }
}
