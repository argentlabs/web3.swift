//
//  MulticallTests.swift
//  web3swiftTests
//
//  Created by David Rodrigues on 28/10/2020.
//  Copyright © 2020 Argent Labs Limited. All rights reserved.
//

import XCTest
@testable import web3

class MulticallTests: XCTestCase {
    var client: EthereumClient!
    var multicall: Multicall!
    let testContractAddress = EthereumAddress(TestConfig.erc20Contract)

    override func setUp() {
        super.setUp()
        self.client = EthereumClient(url: URL(string: TestConfig.clientUrl)!)
        self.multicall = Multicall(client: client!)
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
            name = try result.get()
        }
        
        try aggregator.append(ERC20Functions.symbol(contract: testContractAddress))
        let response = try await multicall.aggregate(calls: aggregator.calls)
        let symbol = try ERC20Responses.symbolResponse(data: try response.outputs[2].get())?.value
        
        XCTAssertEqual(symbol, "BOKKY")
        XCTAssertEqual(decimals, 18)
        XCTAssertEqual(name, "BokkyPooBah Test Token")
    }
}
