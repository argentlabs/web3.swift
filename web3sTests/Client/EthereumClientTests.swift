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

struct TransferMatchingSignatureEvent: ABIEvent {
    public static let name = "Transfer"
    public static let types: [ABIType.Type] = [ EthereumAddress.self , EthereumAddress.self , BigUInt.self]
    public static let typesIndexed = [true, true, false]
    public let log: EthereumLog
    
    public let from: EthereumAddress
    public let to: EthereumAddress
    public let value: BigUInt
    
    public init?(topics: [ABIType], data: [ABIType], log: EthereumLog) throws {
        try TransferMatchingSignatureEvent.checkParameters(topics, data)
        self.log = log
        
        self.from = try topics[0].decoded()
        self.to = try topics[1].decoded()
        
        self.value = try data[0].decoded()
    }
}


class EthereumClientTests: XCTestCase {
    var client: EthereumClient?
    var account: EthereumAccount?
    let timeout = 10.0
    
    override func setUp() {
        super.setUp()
        self.client = EthereumClient(url: URL(string: TestConfig.clientUrl)!)
        self.account = try? EthereumAccount(keyStorage: TestEthereumKeyStorage(privateKey: TestConfig.privateKey))
        print("Public address: \(self.account?.address ?? "NONE")")
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testEthGetBalance() {
        let expectation = XCTestExpectation(description: "get remote balance")
        client?.eth_getBalance(address: account?.address ?? "", block: .Latest, completion: { (error, balance) in
            XCTAssertNotNil(balance, "Balance not available: \(error?.localizedDescription ?? "no error")")
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: timeout)
    }
    
    func testEthGetBalanceIncorrectAddress() {
        let expectation = XCTestExpectation(description: "get remote balance incorrect")
        
        client?.eth_getBalance(address: "0xnig42niog2", block: .Latest, completion: { (error, balance) in
            XCTAssertNotNil(error, "Balance error not available")
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: timeout)
    }
    
    func testNetVersion() {
        let expectation = XCTestExpectation(description: "get net version")
        client?.net_version(completion: { (error, network) in
            XCTAssertEqual(network, EthereumNetwork.Ropsten, "Network incorrect: \(error?.localizedDescription ?? "no error")")
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: timeout)
    }
    
    func testEthGasPrice() {
        let expectation = XCTestExpectation(description: "get gas price")
        client?.eth_gasPrice(completion: { (error, gas) in
            XCTAssertNotNil(gas, "Gas not available: \(error?.localizedDescription ?? "no error")")
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: timeout)
    }
    
    func testEthBlockNumber() {
        let expectation = XCTestExpectation(description: "get current block number")
        client?.eth_blockNumber(completion: { (error, block) in
            XCTAssertNotNil(block, "Block not available: \(error?.localizedDescription ?? "no error")")
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: timeout)
    }
    
    func testEthGetCode() {
        let expectation = XCTestExpectation(description: "get contract code")
        client?.eth_getCode(address: "0x112234455c3a32fd11230c42e7bccd4a84e02010", completion: { (error, code) in
            XCTAssertNotNil(code, "Contract code not available: \(error?.localizedDescription ?? "no error")")
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: timeout)
    }
    
    func testEthSendRawTransaction() {
        let expectation = XCTestExpectation(description: "send raw transaction")
            
        let tx = EthereumTransaction(from: nil, to: EthereumAddress("0x3c1bd6b420448cf16a389c8b0115ccb3660bb854"), value: BigUInt(1600000), data: nil, nonce: 2, gasPrice: BigUInt(4000000), gasLimit: BigUInt(50000), chainId: EthereumNetwork.Ropsten.intValue)
        
        self.client?.eth_sendRawTransaction(tx, withAccount: self.account!, completion: { (error, txHash) in
            XCTAssertNotNil(txHash, "Transaction hash not available: \(error?.localizedDescription ?? "no error")")
            expectation.fulfill()
        })
    
        wait(for: [expectation], timeout: timeout)
    }
    
    func testEthGetTransactionCount() {
        let expectation = XCTestExpectation(description: "get transaction receipt")
        
        client?.eth_getTransactionCount(address: account!.address, block: .Latest, completion: { (error, count) in
            XCTAssertNotNil(count, "Transaction count not available: \(error?.localizedDescription ?? "no error")")
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: timeout)
    }
    
    func testEthGetTransactionCountPending() {
        let expectation = XCTestExpectation(description: "get transaction receipt")
        
        client?.eth_getTransactionCount(address: account!.address, block: .Pending, completion: { (error, count) in
            XCTAssertNotNil(count, "Transaction count not available: \(error?.localizedDescription ?? "no error")")
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: timeout)
    }
    
    func testEthGetTransactionReceipt() {
        let expectation = XCTestExpectation(description: "get transaction receipt")
       
        let txHash = "0xc51002441dc669ad03697fd500a7096c054b1eb2ce094821e68831a3666fc878"
        client?.eth_getTransactionReceipt(txHash: txHash, completion: { (error, receipt) in
            XCTAssertNotNil(receipt, "Transaction receipt not available: \(error?.localizedDescription ?? "no error")")
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: timeout)
    }
    
    func testEthCall() {
        let expectation = XCTestExpectation(description: "send raw transaction")
        
        let tx = EthereumTransaction(from: nil, to: EthereumAddress("0x3c1bd6b420448cf16a389c8b0115ccb3660bb854"), value: BigUInt(1800000), data: nil, nonce: 2, gasPrice: BigUInt(400000), gasLimit: BigUInt(50000), chainId: EthereumNetwork.Ropsten.intValue)
        client?.eth_call(tx, block: .Latest, completion: { (error, txHash) in
            XCTAssertNotNil(txHash, "Transaction hash not available: \(error?.localizedDescription ?? "no error")")
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: timeout)
    }
    
    func testEthGetLogs() {
        let expectation = XCTestExpectation(description: "send raw transaction")
        
        client?.eth_getLogs(addresses: ["0x23d0a442580c01e420270fba6ca836a8b2353acb"], topics: nil, fromBlock: EthereumBlock.Number(0), toBlock: .Latest, completion: { (error, logs) in
            XCTAssertNotNil(logs, "Logs not available \(error?.localizedDescription ?? "no error")")
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: timeout)
    }
    
    func testGivenGenesisBlock_ThenReturnsByNumber() {
        let expectation = XCTestExpectation(description: "get block by number")
        
        client?.eth_getBlockByNumber(.Number(0)) { error, block in
            XCTAssertNil(error)
            
            XCTAssertEqual(block?.timestamp.timeIntervalSince1970, 0)
            XCTAssertEqual(block?.transactions.count, 0)
            XCTAssertEqual(block?.number, .Number(0))
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: timeout)
    }

    func testGivenLatestBlock_ThenReturnsByNumber() {
        let expectation = XCTestExpectation(description: "get block by number")
        
        client?.eth_getBlockByNumber(.Latest) { error, block in
            XCTAssertNil(error)
            
            XCTAssert((block?.transactions.count ?? 0) > 0);
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: timeout)
    }
    
    func testGivenExistingBlock_ThenGetsBlockByNumber() {
        let expectation = XCTestExpectation(description: "get block by number")
        
        client?.eth_getBlockByNumber(.Number(3415757)) { error, block in
            XCTAssertNil(error)
            
            XCTAssertEqual(block?.number, .Number(3415757))
            XCTAssertEqual(block?.timestamp.timeIntervalSince1970, 1528711895)
            XCTAssertEqual(block?.transactions.count, 40)
            XCTAssertEqual(block?.transactions.first, "0x387867d052b3f89fb87937572891118aa704c1ba604c157bbd9c5a07f3a7e5cd")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: timeout)
    }
    
    func testGivenUnexistingBlockNumber_ThenGetBlockByNumberReturnsError() {
        let expectation = XCTestExpectation(description: "get block by number")
        
        client?.eth_getBlockByNumber(.Number(Int.max)) { error, block in
            XCTAssertNotNil(error)
            XCTAssertNil(block)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: timeout)
    }
    
    func testGivenMinedTransactionHash_ThenGetsTransactionByHash() {
        let expectation = XCTestExpectation(description: "get transaction by hash")
        
        client?.eth_getTransaction(byHash: "0x014726c783ab2fd6828a9ca556850bccfc66f70926f411274eaf886385c704af") { error, transaction in
            XCTAssertNil(error)
            XCTAssertEqual(transaction?.from?.value, "0xbbf5029fd710d227630c8b7d338051b8e76d50b3")
            XCTAssertEqual(transaction?.to.value, "0x37f13b5ffcc285d2452c0556724afb22e58b6bbe")
            XCTAssertEqual(transaction?.gas, "30400")
            XCTAssertEqual(transaction?.gasPrice, BigUInt(hex: "0x9184e72a000"))
            XCTAssertEqual(transaction?.nonce, 973253)
            XCTAssertEqual(transaction?.value, BigUInt(hex: "0x56bc75e2d63100000"))
            XCTAssertEqual(transaction?.blockNumber, EthereumBlock.Number(3439303))
            XCTAssertEqual(transaction?.hash?.web3.hexString, "0x014726c783ab2fd6828a9ca556850bccfc66f70926f411274eaf886385c704af")
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: timeout)
    }
    
    func testGivenUnexistingTransactionHash_ThenErrorsGetTransactionByHash() {
        let expectation = XCTestExpectation(description: "get transaction by hash")
        
        client?.eth_getTransaction(byHash: "0x01234") { error, transaction in
            XCTAssertNotNil(error)
            XCTAssertNil(transaction)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: timeout)
    }
    
    func testGivenNoFilters_WhenMatchingSingleTransferEvents_AllEventsReturned() {
        let expectation = XCTestExpectation(description: "get events")
        
        let to = try! ABIEncoder.encode("0x3C1Bd6B420448Cf16A389C8b0115CCB3660bB854", forType: ABIRawType.FixedAddress)
        
        client?.getEvents(addresses: nil,
                          topics: [try! ERC20Events.Transfer.signature(), nil, String(hexFromBytes: to), nil],
                          fromBlock: .Earliest,
                          toBlock: .Latest,
                          eventTypes: [ERC20Events.Transfer.self]) { (error, events, logs) in
            XCTAssertNil(error)
            XCTAssertEqual(events.count, 2)
            XCTAssertEqual(logs.count, 0)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: timeout)
    }
    
    func testGivenNoFilters_WhenMatchingMultipleTransferEvents_BothEventsReturned() {
        let expectation = XCTestExpectation(description: "get events")
        
        let to = try! ABIEncoder.encode("0x3C1Bd6B420448Cf16A389C8b0115CCB3660bB854", forType: ABIRawType.FixedAddress)
        
        client?.getEvents(addresses: nil,
                          topics: [try! ERC20Events.Transfer.signature(), nil, String(hexFromBytes: to), nil],
                          fromBlock: .Earliest,
                          toBlock: .Latest,
                          eventTypes: [ERC20Events.Transfer.self, TransferMatchingSignatureEvent.self]) { (error, events, logs) in
                            XCTAssertNil(error)
                            XCTAssertEqual(events.count, 4)
                            XCTAssertEqual(logs.count, 0)
                            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: timeout)
    }
    
    func testGivenContractFilter_WhenMatchingSingleTransferEvents_OnlyMatchingSourceEventReturned() {
        let expectation = XCTestExpectation(description: "get events")
        
        let to = try! ABIEncoder.encode("0x3C1Bd6B420448Cf16A389C8b0115CCB3660bB854", forType: ABIRawType.FixedAddress)
        let filters = [
            EventFilter(type: ERC20Events.Transfer.self, allowedSenders: [EthereumAddress("0xdb0040451f373949a4be60dcd7b6b8d6e42658b6")])
        ]
        
        client?.getEvents(addresses: nil,
                          topics: [try! ERC20Events.Transfer.signature(), nil, String(hexFromBytes: to), nil],
                          fromBlock: .Earliest,
                          toBlock: .Latest,
                          matching: filters) { (error, events, logs) in
                            XCTAssertNil(error)
                            XCTAssertEqual(events.count, 1)
                            XCTAssertEqual(logs.count, 1)
                            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: timeout)
    }
    
    func testGivenContractFilter_WhenMatchingMultipleTransferEvents_OnlyMatchingSourceEventsReturned() {
        let expectation = XCTestExpectation(description: "get events")
        
        let to = try! ABIEncoder.encode("0x3C1Bd6B420448Cf16A389C8b0115CCB3660bB854", forType: ABIRawType.FixedAddress)
        let filters = [
            EventFilter(type: ERC20Events.Transfer.self, allowedSenders: [EthereumAddress("0xdb0040451f373949a4be60dcd7b6b8d6e42658b6")]),
            EventFilter(type: TransferMatchingSignatureEvent.self, allowedSenders: [EthereumAddress("0xdb0040451f373949a4be60dcd7b6b8d6e42658b6")])
        ]
        
        client?.getEvents(addresses: nil,
                          topics: [try! ERC20Events.Transfer.signature(), nil, String(hexFromBytes: to), nil],
                          fromBlock: .Earliest,
                          toBlock: .Latest,
                          matching: filters) { (error, events, logs) in
                            XCTAssertNil(error)
                            XCTAssertEqual(events.count, 2)
                            XCTAssertEqual(logs.count, 2)
                            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: timeout)
    }
}
