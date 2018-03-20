//
//  EthereumClientTests.swift
//  web3sTests
//
//  Created by Matt Marshall on 09/03/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import XCTest
@testable import web3swift
import BigInt

class EthereumClientTests: XCTestCase {
    var client: EthereumClient?
    var account: EthereumAccount?
    let timeout = 10.0
    
    override func setUp() {
        super.setUp()
        self.client = EthereumClient(url: URL(string: TestConfig.clientUrl)!)
        self.account = try! EthereumAccount(keyStorage: TestEthereumKeyStorage(privateKey: TestConfig.privateKey))
        print("Public address: \(self.account?.address ?? "NONE")")
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testEthGetBalance() {
        let expectation = XCTestExpectation(description: "get remote balance")
        client?.eth_getBalance(address: account!.address, block: .Latest, completion: { (error, balance) in
            XCTAssert(balance != nil, "Balance not available: \(error?.localizedDescription ?? "no error")")
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: timeout)
    }
    
    func testEthGetBalanceIncorrectAddress() {
        let expectation = XCTestExpectation(description: "get remote balance incorrect")
        
        client?.eth_getBalance(address: "0xnig42niog2", block: .Latest, completion: { (error, balance) in
            XCTAssert(error != nil, "Balance error not available")
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: timeout)
    }
    
    func testNetVersion() {
        let expectation = XCTestExpectation(description: "get net version")
        client?.net_version(completion: { (error, network) in
            XCTAssert(network! == EthereumNetwork.Ropsten, "Network incorrect: \(error?.localizedDescription ?? "no error")")
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: timeout)
    }
    
    func testEthGasPrice() {
        let expectation = XCTestExpectation(description: "get gas price")
        client?.eth_gasPrice(completion: { (error, gas) in
            XCTAssert(gas != nil, "Gas not available: \(error?.localizedDescription ?? "no error")")
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: timeout)
    }
    
    func testEthBlockNumber() {
        let expectation = XCTestExpectation(description: "get current block number")
        client?.eth_blockNumber(completion: { (error, block) in
            XCTAssert(block != nil, "Block not available: \(error?.localizedDescription ?? "no error")")
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: timeout)
    }
    
    func testEthGetCode() {
        let expectation = XCTestExpectation(description: "get contract code")
        client?.eth_getCode(address: "0x112234455c3a32fd11230c42e7bccd4a84e02010", completion: { (error, code) in
            XCTAssert(code != nil, "Contract code not available: \(error?.localizedDescription ?? "no error")")
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: timeout)
    }
    
    func testEthSendRawTransaction() {
        let expectation = XCTestExpectation(description: "send raw transaction")
            
        let tx = EthereumTransaction(to: "0x3c1bd6b420448cf16a389c8b0115ccb3660bb854", value: Ether(wei: 1600000), data: nil, nonce: 2, gasPrice: Ether(gwei: 400), gasLimit: BigUInt(50000), chainId: EthereumNetwork.Ropsten.intValue)
        
        self.client?.eth_sendRawTransaction(tx, withAccount: self.account!, completion: { (error, txHash) in
            XCTAssert(txHash != nil, "Transaction hash not available: \(error?.localizedDescription ?? "no error")")
            expectation.fulfill()
        })
    
        wait(for: [expectation], timeout: timeout)
    }
    
    func testEthGetTransactionCount() {
        let expectation = XCTestExpectation(description: "get transaction receipt")
        
        client?.eth_getTransactionCount(address: account!.address, block: .Latest, completion: { (error, count) in
            XCTAssert(count != nil, "Transaction count not available: \(error?.localizedDescription ?? "no error")")
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: timeout)
    }
    
    func testEthGetTransactionCountPending() {
        let expectation = XCTestExpectation(description: "get transaction receipt")
        
        client?.eth_getTransactionCount(address: account!.address, block: .Pending, completion: { (error, count) in
            XCTAssert(count != nil, "Transaction count not available: \(error?.localizedDescription ?? "no error")")
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: timeout)
    }
    
    func testEthGetTransactionReceipt() {
        let expectation = XCTestExpectation(description: "get transaction receipt")
       
        let txHash = "0xc51002441dc669ad03697fd500a7096c054b1eb2ce094821e68831a3666fc878"
        client?.eth_getTransactionReceipt(txHash: txHash, completion: { (error, receipt) in
            XCTAssert(receipt != nil, "Transaction receipt not available: \(error?.localizedDescription ?? "no error")")
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: timeout)
    }
    
    func testEthCall() {
        let expectation = XCTestExpectation(description: "send raw transaction")
        
        let tx = EthereumTransaction(to: "0x3c1bd6b420448cf16a389c8b0115ccb3660bb854", value: Ether(wei: 1800000), data: nil, nonce: 2, gasPrice: Ether(gwei: 400), gasLimit: BigUInt(50000), chainId: EthereumNetwork.Ropsten.intValue)
        client?.eth_call(tx, block: .Latest, completion: { (error, txHash) in
            XCTAssert(txHash != nil, "Transaction hash not available: \(error?.localizedDescription ?? "no error")")
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: timeout)
    }
    
    func testEthGetLogs() {
        let expectation = XCTestExpectation(description: "send raw transaction")
        
        client?.eth_getLogs(addresses: ["0x23d0a442580c01e420270fba6ca836a8b2353acb"], topics: nil, fromBlock: EthereumBlock.Number(0), toBlock: .Latest, completion: { (error, logs) in
            XCTAssert(logs != nil, "Logs not available \(error?.localizedDescription ?? "no error")")
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: timeout)
    }
    
}
