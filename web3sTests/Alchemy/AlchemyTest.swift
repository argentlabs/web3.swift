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
    
    let uniswapTokenContract = EthereumAddress("0x1f9840a85d5af5bf1d1762f925bdaddc4201f984")
    
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
    
    func testDefaultTokenBalances() async throws {
        let owner = EthereumAddress("0xb739D0895772DBB71A89A3754A160269068f0D45")
        let balances = try await mainnetClient.alchemyTokenBalances(address: owner)
        XCTAssertEqual(balances.count, 100)
    }
    
    func testTokenBalances() async throws {
        
        let owner = EthereumAddress("0xb739D0895772DBB71A89A3754A160269068f0D45")
        let tokens = [
            EthereumAddress("0x1f9840a85d5af5bf1d1762f925bdaddc4201f984"), // Uniswap
            EthereumAddress("0xE41d2489571d322189246DaFA5ebDe1F4699F498"), // ZRX
            EthereumAddress("0x85Eee30c52B0b379b046Fb0F85F4f3Dc3009aFEC"), // KEEP
            EthereumAddress("0x04Fa0d235C4abf4BcF4787aF4CF447DE572eF828"), // UMA token
        ]
        let balances = try await mainnetClient.alchemyTokenBalances(address: owner, tokenAddresses: tokens)
    
        XCTAssertEqual(tokens.count, balances.count)    
    }
    
    func testErc20Balance() async throws {
        let erc20 = ERC20(client: mainnetClient)
        let balance = try await erc20.balanceOf(tokenContract: uniswapTokenContract, address: EthereumAddress("0xb739D0895772DBB71A89A3754A160269068f0D45"))
        XCTAssertGreaterThan(balance, 0)
    }
    
    func testTokenMetadata() async throws {
        let gysrAddress = EthereumAddress("0xbea98c05eeae2f3bc8c3565db7551eb738c8ccab")
        let metadata = try await mainnetClient.alchemy_tokenMetadata(tokenAddresss: gysrAddress)
        XCTAssertEqual(metadata.name, "GYSR")
        XCTAssertEqual(metadata.symbol, "GYSR")
        XCTAssertEqual(metadata.logo, URL(string: "https://static.alchemyapi.io/images/assets/7661.png")!)
        XCTAssertEqual(metadata.decimals, 18)
    }
}
