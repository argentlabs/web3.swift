//
//  MulticallTests.swift
//  web3swiftTests
//
//  Created by David Rodrigues on 28/10/2020.
//  Copyright © 2020 Argent Labs Limited. All rights reserved.
//

import XCTest
@testable import web3swift

class MulticallTests: XCTestCase {
    var client: EthereumClient!
    var multicall: Multicall!
    let testContractAddress = EthereumAddress(TestConfig.erc20Contract)

    override func setUp() {
        super.setUp()
        self.client = EthereumClient(url: URL(string: TestConfig.clientUrl)!)
        self.multicall = Multicall(client: client!)
    }

    func testNameAndSymbol() throws {
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

        let expect = expectation(description: "Get token name and symbol")
        multicall.aggregate(calls: aggregator.calls) { result in
            do {
                switch result {
                case .failure(let error):
                    XCTFail("Multicall failed with error: \(error)")
                case .success(let response):
                    let symbol = try ERC20Responses.symbolResponse(data: try response.outputs[2].get())?.value
                     XCTAssertEqual(symbol, "BOKKY")
                }
            } catch {
                XCTFail("Unexpected failure while handling output")
            }
            expect.fulfill()
        }
        waitForExpectations(timeout: 10)

        XCTAssertEqual(decimals, 18)
        XCTAssertEqual(name, "BokkyPooBah Test Token")
    }
}
