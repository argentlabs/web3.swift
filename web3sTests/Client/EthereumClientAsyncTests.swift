//
//  EthereumClientAsyncTests.swift
//  web3sTests
//
//  Created by Ronald Mannak on 08/14/2021.
//  Copyright © 2021 Starling Protocol Inc. All rights reserved.
//

import XCTest
@testable import web3
import BigInt


class EthereumClientAsyncTests: XCTestCase {
    var client: EthereumClient?
    var mainnetClient: EthereumClient?
    var account: EthereumAccount?
    let timeout = 10.0
    
    override func setUp() {
        super.setUp()
        self.client = EthereumClient(url: URL(string: TestConfig.clientUrl)!)
        self.mainnetClient = EthereumClient(url: URL(string: TestConfig.mainnetClientUrl)!)
        self.account = try? EthereumAccount(keyStorage: TestEthereumKeyStorage(privateKey: TestConfig.privateKey))
        print("Public address: \(self.account?.address.value ?? "NONE")")
    }
    
    override func tearDown() {
        super.tearDown()
    }
    

//    
//    func testEthGetBalanceIncorrectAddress() {
//        let expectation = XCTestExpectation(description: "get remote balance incorrect")
//        
//        client?.eth_getBalance(address: EthereumAddress("0xnig42niog2"), block: .Latest, completion: { (error, balance) in
//            XCTAssertNotNil(error, "Balance error not available")
//            expectation.fulfill()
//        })
//        
//        wait(for: [expectation], timeout: timeout)
//    }
    
    func testNetVersion() async {
        let expectation = XCTestExpectation(description: "get net version")
        do {
            let network = try await client!.net_version()
            XCTAssertEqual(network, EthereumNetwork.Ropsten)
            expectation.fulfill()
        } catch {
            XCTFail(error.localizedDescription)
        }
      
        wait(for: [expectation], timeout: timeout)
    }
    
    func testEthGasPrice() async {
        let expectation = XCTestExpectation(description: "get gas price")
        do {
            let gasPrice = try await client!.eth_gasPrice()
            XCTAssertGreaterThan(gasPrice, 0)
            expectation.fulfill()
        } catch {
            XCTFail(error.localizedDescription)
        }
        
        wait(for: [expectation], timeout: timeout)
    }
    
    func testEthBlockNumber() async {
        let expectation = XCTestExpectation(description: "get current block number")
        do {
            let block = try await client!.eth_blockNumber()
            XCTAssertGreaterThan(block, 1)
            expectation.fulfill()
        } catch {
            XCTFail(error.localizedDescription)
        }

        wait(for: [expectation], timeout: timeout)
    }
    
    func testEthGetBalance() async {
        let expectation = XCTestExpectation(description: "get remote balance")
        do {
            let balance = try await client!.eth_getBalance(address: account?.address ?? .zero, block: .latest)
            XCTAssertGreaterThan(balance, 0)
            expectation.fulfill()
        } catch {
            XCTFail(error.localizedDescription)
        }
        
        wait(for: [expectation], timeout: timeout)
    }
    
//    func testEthGetCode() {
//        let expectation = XCTestExpectation(description: "get contract code")
//        client?.eth_getCode(address: EthereumAddress("0x112234455c3a32fd11230c42e7bccd4a84e02010"), completion: { (error, code) in
//            XCTAssertNotNil(code, "Contract code not available: \(error?.localizedDescription ?? "no error")")
//            expectation.fulfill()
//        })
//
//        wait(for: [expectation], timeout: timeout)
//    }
//
//    func testEthSendRawTransaction() {
//        let expectation = XCTestExpectation(description: "send raw transaction")
//
//        let tx = EthereumTransaction(from: nil, to: EthereumAddress("0x3c1bd6b420448cf16a389c8b0115ccb3660bb854"), value: BigUInt(1600000), data: nil, nonce: 2, gasPrice: BigUInt(4000000), gasLimit: BigUInt(50000), chainId: EthereumNetwork.Ropsten.intValue)
//
//        self.client?.eth_sendRawTransaction(tx, withAccount: self.account!, completion: { (error, txHash) in
//            XCTAssertNotNil(txHash, "No tx hash, ensure key is valid in TestConfig.swift")
//            expectation.fulfill()
//        })
//
//        wait(for: [expectation], timeout: timeout)
//    }
//
//    func testEthGetTransactionCount() {
//        let expectation = XCTestExpectation(description: "get transaction receipt")
//
//        client?.eth_getTransactionCount(address: account!.address, block: .Latest, completion: { (error, count) in
//            XCTAssertNotNil(count, "Transaction count not available: \(error?.localizedDescription ?? "no error")")
//            expectation.fulfill()
//        })
//
//        wait(for: [expectation], timeout: timeout)
//    }
//
//    func testEthGetTransactionCountPending() {
//        let expectation = XCTestExpectation(description: "get transaction receipt")
//
//        client?.eth_getTransactionCount(address: account!.address, block: .Pending, completion: { (error, count) in
//            XCTAssertNotNil(count, "Transaction count not available: \(error?.localizedDescription ?? "no error")")
//            expectation.fulfill()
//        })
//
//        wait(for: [expectation], timeout: timeout)
//    }
//
//    func testEthGetTransactionReceipt() {
//        let expectation = XCTestExpectation(description: "get transaction receipt")
//
//        let txHash = "0xc51002441dc669ad03697fd500a7096c054b1eb2ce094821e68831a3666fc878"
//        client?.eth_getTransactionReceipt(txHash: txHash, completion: { (error, receipt) in
//            XCTAssertNotNil(receipt, "Transaction receipt not available: \(error?.localizedDescription ?? "no error")")
//            expectation.fulfill()
//        })
//
//        wait(for: [expectation], timeout: timeout)
//    }
//
//    func testEthCall() {
//        let expectation = XCTestExpectation(description: "send raw transaction")
//
//        let tx = EthereumTransaction(from: nil, to: EthereumAddress("0x3c1bd6b420448cf16a389c8b0115ccb3660bb854"), value: BigUInt(1800000), data: nil, nonce: 2, gasPrice: BigUInt(400000), gasLimit: BigUInt(50000), chainId: EthereumNetwork.Ropsten.intValue)
//        client?.eth_call(tx, block: .Latest, completion: { (error, txHash) in
//            XCTAssertNotNil(txHash, "Transaction hash not available: \(error?.localizedDescription ?? "no error")")
//            expectation.fulfill()
//        })
//
//        wait(for: [expectation], timeout: timeout)
//    }
//
//    func testSimpleEthGetLogs() {
//        let expectation = XCTestExpectation(description: "get logs")
//
//        client?.eth_getLogs(addresses: [EthereumAddress("0x23d0a442580c01e420270fba6ca836a8b2353acb")], topics: nil, fromBlock: .Earliest, toBlock: .Latest, completion: { (error, logs) in
//            XCTAssertNotNil(logs, "Logs not available \(error?.localizedDescription ?? "no error")")
//            expectation.fulfill()
//        })
//
//        wait(for: [expectation], timeout: timeout)
//    }
//
//    func testOrTopicsEthGetLogs() {
//        let expectation = XCTestExpectation(description: "get logs")
//
//        // Deposit/Withdrawal event to specific address
//        client?.eth_getLogs(addresses: nil, orTopics: [["0xe1fffcc4923d04b559f4d29a8bfc6cda04eb5b0d3c460751c2402c5c5cc9109c", "0x7fcf532c15f0a6db0bd6d0e038bea71d30d808c7d98cb3bf7268a95bf5081b65"], ["0x000000000000000000000000655ef694b98e55977a93259cb3b708560869a8f3"]], fromBlock: .Number(6540313), toBlock: .Number(6540397), completion: { (error, logs) in
//            XCTAssertEqual(logs?.count, 2)
//            XCTAssertNotNil(logs, "Logs not available \(error?.localizedDescription ?? "no error")")
//            expectation.fulfill()
//        })
//
//        wait(for: [expectation], timeout: timeout)
//    }
//
//    func testGivenGenesisBlock_ThenReturnsByNumber() {
//        let expectation = XCTestExpectation(description: "get block by number")
//
//        client?.eth_getBlockByNumber(.Number(0)) { error, block in
//            XCTAssertNil(error)
//
//            XCTAssertEqual(block?.timestamp.timeIntervalSince1970, 0)
//            XCTAssertEqual(block?.transactions.count, 0)
//            XCTAssertEqual(block?.number, .Number(0))
//            expectation.fulfill()
//        }
//
//        wait(for: [expectation], timeout: timeout)
//    }
//
//    func testGivenLatestBlock_ThenReturnsByNumber() {
//        let expectation = XCTestExpectation(description: "get block by number")
//
//        client?.eth_getBlockByNumber(.Latest) { error, block in
//            XCTAssertNil(error)
//            XCTAssertNotNil(block?.number.intValue)
//            expectation.fulfill()
//        }
//
//        wait(for: [expectation], timeout: timeout)
//    }
//
//    func testGivenExistingBlock_ThenGetsBlockByNumber() {
//        let expectation = XCTestExpectation(description: "get block by number")
//
//        client?.eth_getBlockByNumber(.Number(3415757)) { error, block in
//            XCTAssertNil(error)
//
//            XCTAssertEqual(block?.number, .Number(3415757))
//            XCTAssertEqual(block?.timestamp.timeIntervalSince1970, 1528711895)
//            XCTAssertEqual(block?.transactions.count, 40)
//            XCTAssertEqual(block?.transactions.first, "0x387867d052b3f89fb87937572891118aa704c1ba604c157bbd9c5a07f3a7e5cd")
//            expectation.fulfill()
//        }
//
//        wait(for: [expectation], timeout: timeout)
//    }
//
//    func testGivenUnexistingBlockNumber_ThenGetBlockByNumberReturnsError() {
//        let expectation = XCTestExpectation(description: "get block by number")
//
//        client?.eth_getBlockByNumber(.Number(Int.max)) { error, block in
//            XCTAssertNotNil(error)
//            XCTAssertNil(block)
//            expectation.fulfill()
//        }
//
//        wait(for: [expectation], timeout: timeout)
//    }
//
//    func testGivenMinedTransactionHash_ThenGetsTransactionByHash() {
//        let expectation = XCTestExpectation(description: "get transaction by hash")
//
//        client?.eth_getTransaction(byHash: "0x014726c783ab2fd6828a9ca556850bccfc66f70926f411274eaf886385c704af") { error, transaction in
//            XCTAssertNil(error)
//            XCTAssertEqual(transaction?.from?.value, "0xbbf5029fd710d227630c8b7d338051b8e76d50b3")
//            XCTAssertEqual(transaction?.to.value, "0x37f13b5ffcc285d2452c0556724afb22e58b6bbe")
//            XCTAssertEqual(transaction?.gas, "30400")
//            XCTAssertEqual(transaction?.gasPrice, BigUInt(hex: "0x9184e72a000"))
//            XCTAssertEqual(transaction?.nonce, 973253)
//            XCTAssertEqual(transaction?.value, BigUInt(hex: "0x56bc75e2d63100000"))
//            XCTAssertEqual(transaction?.blockNumber, EthereumBlock.Number(3439303))
//            XCTAssertEqual(transaction?.hash?.web3.hexString, "0x014726c783ab2fd6828a9ca556850bccfc66f70926f411274eaf886385c704af")
//
//            expectation.fulfill()
//        }
//
//        wait(for: [expectation], timeout: timeout)
//    }
//
//    func testGivenUnexistingTransactionHash_ThenErrorsGetTransactionByHash() {
//        let expectation = XCTestExpectation(description: "get transaction by hash")
//
//        client?.eth_getTransaction(byHash: "0x01234") { error, transaction in
//            XCTAssertNotNil(error)
//            XCTAssertNil(transaction)
//            expectation.fulfill()
//        }
//
//        wait(for: [expectation], timeout: timeout)
//    }
//
//    func testGivenNoFilters_WhenMatchingSingleTransferEvents_AllEventsReturned() {
//        let expectation = XCTestExpectation(description: "get events")
//
//        let to = try! ABIEncoder.encode(EthereumAddress("0x3C1Bd6B420448Cf16A389C8b0115CCB3660bB854"))
//
//        client?.getEvents(addresses: nil,
//                          topics: [try! ERC20Events.Transfer.signature(), nil, to.hexString, nil],
//                          fromBlock: .Earliest,
//                          toBlock: .Latest,
//                          eventTypes: [ERC20Events.Transfer.self]) { (error, events, logs) in
//            XCTAssertNil(error)
//            XCTAssertEqual(events.count, 2)
//            XCTAssertEqual(logs.count, 0)
//            expectation.fulfill()
//        }
//
//        wait(for: [expectation], timeout: timeout)
//    }
//
//    func testGivenNoFilters_WhenMatchingMultipleTransferEvents_BothEventsReturned() {
//        let expectation = XCTestExpectation(description: "get events")
//
//        let to = try! ABIEncoder.encode(EthereumAddress("0x3C1Bd6B420448Cf16A389C8b0115CCB3660bB854"))
//
//        client?.getEvents(addresses: nil,
//                          topics: [try! ERC20Events.Transfer.signature(), nil, to.hexString, nil],
//                          fromBlock: .Earliest,
//                          toBlock: .Latest,
//                          eventTypes: [ERC20Events.Transfer.self, TransferMatchingSignatureEvent.self]) { (error, events, logs) in
//                            XCTAssertNil(error)
//                            XCTAssertEqual(events.count, 4)
//                            XCTAssertEqual(logs.count, 0)
//                            expectation.fulfill()
//        }
//
//        wait(for: [expectation], timeout: timeout)
//    }
//
//    func testGivenContractFilter_WhenMatchingSingleTransferEvents_OnlyMatchingSourceEventReturned() {
//        let expectation = XCTestExpectation(description: "get events")
//
//        let to = try! ABIEncoder.encodeRaw("0x3C1Bd6B420448Cf16A389C8b0115CCB3660bB854", forType: ABIRawType.FixedAddress)
//        let filters = [
//            EventFilter(type: ERC20Events.Transfer.self, allowedSenders: [EthereumAddress("0xdb0040451f373949a4be60dcd7b6b8d6e42658b6")])
//        ]
//
//        client?.getEvents(addresses: nil,
//                          topics: [try! ERC20Events.Transfer.signature(), nil, to.hexString, nil],
//                          fromBlock: .Earliest,
//                          toBlock: .Latest,
//                          matching: filters) { (error, events, logs) in
//                            XCTAssertNil(error)
//                            XCTAssertEqual(events.count, 1)
//                            XCTAssertEqual(logs.count, 1)
//                            expectation.fulfill()
//        }
//
//        wait(for: [expectation], timeout: timeout)
//    }
//
//    func testGivenContractFilter_WhenMatchingMultipleTransferEvents_OnlyMatchingSourceEventsReturned() {
//        let expectation = XCTestExpectation(description: "get events")
//
//        let to = try! ABIEncoder.encode(EthereumAddress("0x3C1Bd6B420448Cf16A389C8b0115CCB3660bB854"))
//        let filters = [
//            EventFilter(type: ERC20Events.Transfer.self, allowedSenders: [EthereumAddress("0xdb0040451f373949a4be60dcd7b6b8d6e42658b6")]),
//            EventFilter(type: TransferMatchingSignatureEvent.self, allowedSenders: [EthereumAddress("0xdb0040451f373949a4be60dcd7b6b8d6e42658b6")])
//        ]
//
//        client?.getEvents(addresses: nil,
//                          topics: [try! ERC20Events.Transfer.signature(), nil, to.hexString, nil],
//                          fromBlock: .Earliest,
//                          toBlock: .Latest,
//                          matching: filters) { (error, events, logs) in
//                            XCTAssertNil(error)
//                            XCTAssertEqual(events.count, 2)
//                            XCTAssertEqual(logs.count, 2)
//                            expectation.fulfill()
//        }
//
//        wait(for: [expectation], timeout: timeout)
//    }
//
//    func test_GivenDynamicArrayResponse_ThenCallReceivesData() {
//        let expect = expectation(description: "call")
//
//        let function = GetGuardians(wallet: EthereumAddress("0x2A6295C34b4136F2C3c1445c6A0338D784fe0ddd"))
//        function.call(withClient: self.client!,
//                      responseType: GetGuardians.Response.self) { (error, response) in
//                        XCTAssertNil(error)
//                        XCTAssertEqual(response?.guardians, [EthereumAddress("0x44fe11c90d2bcbc8267a0e56d55235ddc2b96c4f")])
//                        expect.fulfill()
//        }
//
//        waitForExpectations(timeout: 10)
//    }
//
//    // This is how geth used to work up until a recent version
//    // see https://github.com/ethereum/go-ethereum/pull/21083/
//    // Used to return '0x' in response, and would fail decoding
//    // We'll continue to support this as user of library (and Argent in our case)
//    // works with this assumption.
//    // NOTE: This behaviour will be removed at a later time to fail as expected
//    // NOTE: At the time of writing, this test succeeds as-is in ropsten as nodes behaviour is different. That's why we use a mainnet check here
//    func test_GivenUnimplementedMethod_WhenCallingContract_ThenFailsWith0x() {
//        let expect = expectation(description: "graceful_failure")
//
//        let function = InvalidMethodA(param: .zero)
//
//        function.call(withClient: self.mainnetClient!,
//                      responseType: InvalidMethodA.BoolResponse.self) { (error, response) in
//                        XCTAssertEqual(error, .decodeIssue)
//                        XCTAssertNil(response)
//                        expect.fulfill()
//        }
//
//        waitForExpectations(timeout: 10)
//    }
//    func test_GivenFailingCallMethod_WhenCallingContract_ThenFailsWith0x() {
//        let expect = expectation(description: "graceful_failure")
//
//        let function = InvalidMethodB(param: .zero)
//
//        function.call(withClient: self.mainnetClient!,
//                      responseType: InvalidMethodB.BoolResponse.self) { (error, response) in
//                        XCTAssertEqual(error, .decodeIssue)
//                        XCTAssertNil(response)
//                        expect.fulfill()
//        }
//
//        waitForExpectations(timeout: 10)
//    }
//
//    func test_GivenValidTransaction_ThenEstimatesGas() {
//        let expect = expectation(description: "estimateOK")
//        let function = TransferToken(wallet: EthereumAddress("0xD18dE36e6FB4a5A069f673723Fab71cc00C6CE5F"),
//                                     token: EthereumAddress("0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"),
//                                     to: EthereumAddress("0x2A6295C34b4136F2C3c1445c6A0338D784fe0ddd"),
//                                     amount: 1,
//                                     data: Data(),
//                                     gasPrice: 0,
//                                     gasLimit: 0)
//        client!.eth_estimateGas(try! function.transaction(), withAccount: account!) { (error, value) in
//            XCTAssertNil(error)
//            XCTAssert(value != 0)
//            expect.fulfill()
//        }
//
//        waitForExpectations(timeout: 10)
//    }
}
