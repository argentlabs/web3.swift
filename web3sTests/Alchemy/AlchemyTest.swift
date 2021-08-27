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
    
    func testTokenAllowance() async throws {
        
        // This is a random Ethereum address that recently had approved tokens on Uniswap
        // Since Uniswap always allows the maxInt amount, the allowance is always the same
        let tokenContract = EthereumAddress("0x1f9840a85d5af5bf1d1762f925bdaddc4201f984")
        let owner = EthereumAddress("0x99a16cec9e0c5f3421da53b83b6649a85b3f4054")
        let spender = EthereumAddress("0x2faf487a4414fe77e2327f0bf4ae2a264a776ad2")
        
        let allowance = try await mainnetClient.alchemyTokenAllowance(tokenContract: tokenContract, owner: owner, spender: spender)
        XCTAssertEqual(allowance, BigUInt("79228162514264337593543950335")) // maxValue
        XCTAssertEqual(allowance, "79228162514264337593543950335")
        print("allowance: \(allowance)")
    }
    
}
