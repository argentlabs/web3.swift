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

        try aggregator.append(ERC20Functions.name(contract: testContractAddress))
        try aggregator.append(ERC20Functions.symbol(contract: testContractAddress))

        let expect = expectation(description: "Get token name and symbol")
        multicall.aggregate(calls: aggregator.calls) { result in
            do {
                switch result {
                case .failure(let error):
                    XCTFail("Multicall failed with error: \(error)")
                case .success(let response):
                    let name = try response.outputs[0].value
                        .flatMap { try ERC20Responses.nameResponse(data: $0)?.value }
                    let symbol = try response.outputs[1].value
                        .flatMap { try ERC20Responses.symbolResponse(data: $0)?.value }
                    XCTAssertEqual(name, "BokkyPooBah Test Token")
                    XCTAssertEqual(symbol, "BOKKY")
                }
            } catch {
                XCTFail("Unexpected failure while handling output")
            }
            expect.fulfill()
        }
        waitForExpectations(timeout: 10)
    }
}
