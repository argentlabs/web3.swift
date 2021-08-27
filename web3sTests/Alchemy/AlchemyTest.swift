//
//  File.swift
//  File
//
//  Created by Ronald Mannak on 8/26/21.
//

import XCTest
@testable import web3
import BigInt


class AlchemyTests: XCTestCase {
    var client: EthereumClient!
    var mainnetClient: EthereumClient!
    var account: EthereumAccount!
    
    override func setUp() {
        super.setUp()
        self.client = EthereumClient(url: URL(string: TestConfig.clientUrl)!)
        self.mainnetClient = EthereumClient(url: URL(string: TestConfig.mainnetClientUrl)!)
        self.account = try? EthereumAccount(keyStorage: TestEthereumKeyStorage(privateKey: TestConfig.privateKey))
        print("Public address: \(self.account?.address.value ?? "NONE")")
    }
    
    func testEth_maxPriorityFeePerGas() async throws {
        let fee = try await client.maxPriorityFeePerGas()
        XCTAssertGreaterThan(fee, 0)
    }
    
}
