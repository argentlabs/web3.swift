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
  
    func testEthGetBalanceIncorrectAddress() async throws {
        do {
            _ = try await client!.eth_getBalance(address: EthereumAddress("0xnig42niog2"), block: .latest)
            XCTFail("balance should fail")
        } catch {
            XCTAssertNotNil(error, "Balance error not available")
        }
    }
    
    func testNetVersion() async throws {
        let network = try await client!.net_version()
        XCTAssertEqual(network, EthereumNetwork.Ropsten)
    }
    
    func testEthGasPrice() async throws {
        let gasPrice = try await client!.eth_gasPrice()
        XCTAssertGreaterThan(gasPrice, 0)
    }
    
    func testEthBlockNumber() async throws {
        let block = try await client!.eth_blockNumber()
        XCTAssertGreaterThan(block, 1)
    }
    
    func testEthGetBalance() async throws {
        let balance = try await client!.eth_getBalance(address: account?.address ?? .zero, block: .latest)
        XCTAssertGreaterThan(balance, 0)
    }
    
    func testEthGetCode() async throws {
        let code = try await client!.eth_getCode(address: EthereumAddress("0x112234455c3a32fd11230c42e7bccd4a84e02010"))
        XCTAssertGreaterThan(code.count, 1)
    }
    
    func test_GivenValidTransaction_ThenEstimatesGas() async throws {
        let function = TransferToken(wallet: EthereumAddress("0xD18dE36e6FB4a5A069f673723Fab71cc00C6CE5F"),
                                     token: EthereumAddress("0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"),
                                     to: EthereumAddress("0x2A6295C34b4136F2C3c1445c6A0338D784fe0ddd"),
                                     amount: 1,
                                     data: Data(),
                                     gasPrice: 0,
                                     gasLimit: 0)
        let gas = try await client!.eth_estimateGas(try! function.transaction(), withAccount: account!)
        XCTAssert(gas > 0)
    }

    func testEthSendRawTransaction() async throws {
        let tx = EthereumTransaction(from: nil, to: EthereumAddress("0x3c1bd6b420448cf16a389c8b0115ccb3660bb854"), value: BigUInt(1600000), data: nil, nonce: 2, gasPrice: BigUInt(4000000), gasLimit: BigUInt(50000), chainId: EthereumNetwork.Ropsten.intValue)
        let txHash = try await self.client!.eth_sendRawTransaction(tx, withAccount: self.account!)
        XCTAssert(txHash.count > 0)
    }

    func testEthGetTransactionCount() async throws {
        let count = try await client!.eth_getTransactionCount(address: account!.address, block: .latest)
        XCTAssert(count > 0)
    }
    
    func testEthGetTransactionCountPending() async throws {
        _ = try await client!.eth_getTransactionCount(address: account!.address, block: .pending)
    }
    
    func testEthGetTransactionReceipt() async throws {
        let txHash = "0x9d7282cc7140ac23c709e07cf717bad25605dbc454f6ac22245989afd711e5ec"
        let receipt = try await client!.eth_getTransactionReceipt(txHash: txHash)
        XCTAssertEqual(receipt.transactionHash, "0x9d7282cc7140ac23c709e07cf717bad25605dbc454f6ac22245989afd711e5ec")
        XCTAssertEqual(receipt.blockNumber, BigUInt(10797945))
    }
    
    func testEthGetInvalidTransactionReceipt() async {
        let expectation = XCTestExpectation(description: "get transaction receipt")

        do {
            let txHash = "0x9d7282cc7140ac23c709e07cf717bad25605dbc454f6ac22245989afd711e5e1"
            _ = try await client!.eth_getTransactionReceipt(txHash: txHash)
            XCTFail("invalid receipt found")
        } catch {
            
            if let error = error as? Web3Error, case .noResult = error {
                expectation.fulfill()
            } else if let error = error as? Web3Error, case .noResult = error {
                expectation.fulfill()
            } else {
                XCTFail("fail: \(error)")
            }
        }

        wait(for: [expectation], timeout: timeout)
    }

    func testGivenMinedTransactionHash_ThenGetsTransactionByHash() async throws {
        let transaction = try await client!.eth_getTransaction(byHash: "0x014726c783ab2fd6828a9ca556850bccfc66f70926f411274eaf886385c704af")
        
        XCTAssertEqual(transaction.from?.value, "0xbbf5029fd710d227630c8b7d338051b8e76d50b3")
        XCTAssertEqual(transaction.to.value, "0x37f13b5ffcc285d2452c0556724afb22e58b6bbe")
        XCTAssertEqual(transaction.gas, "30400")
        XCTAssertEqual(transaction.gasPrice, BigUInt(hex: "0x9184e72a000"))
        XCTAssertEqual(transaction.nonce, 973253)
        XCTAssertEqual(transaction.value, BigUInt(hex: "0x56bc75e2d63100000"))
        XCTAssertEqual(transaction.blockNumber, EthereumBlock.number(3439303))
        XCTAssertEqual(transaction.hash?.web3.hexString, "0x014726c783ab2fd6828a9ca556850bccfc66f70926f411274eaf886385c704af")
    }

    func testGivenUnexistingTransactionHash_ThenErrorsGetTransactionByHash() async {
        let expectation = XCTestExpectation(description: "get transaction by hash")

        do {
            let transaction = try await client!.eth_getTransaction(byHash: "0x01234")
            XCTFail("getTransaction should have failed: \(transaction)")
        } catch {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: timeout)
    }

    func testEthCall() async throws {
        let tx = EthereumTransaction(from: nil, to: EthereumAddress("0x3c1bd6b420448cf16a389c8b0115ccb3660bb854"), value: BigUInt(1800000), data: nil, nonce: 2, gasPrice: BigUInt(400000), gasLimit: BigUInt(50000), chainId: EthereumNetwork.Ropsten.intValue)
        let txHash = try await client!.eth_call(tx, block: .latest)
        XCTAssertNotNil(txHash)
    }

    func testSimpleEthGetLogs() async throws {
        _ = try await client!.eth_getLogs(addresses: [EthereumAddress("0x23d0a442580c01e420270fba6ca836a8b2353acb")], topics: nil, fromBlock: .earliest, toBlock: .latest)
    }

    func testOrTopicsEthGetLogs() async throws {
        let logs = try await client!.eth_getLogs(addresses: nil, orTopics: [["0xe1fffcc4923d04b559f4d29a8bfc6cda04eb5b0d3c460751c2402c5c5cc9109c", "0x7fcf532c15f0a6db0bd6d0e038bea71d30d808c7d98cb3bf7268a95bf5081b65"], ["0x000000000000000000000000655ef694b98e55977a93259cb3b708560869a8f3"]], fromBlock: .number(6540313), toBlock: .number(6540397))
        XCTAssertEqual(logs.count, 2)
    }

    func testGivenGenesisBlock_ThenReturnsByNumber() async throws {
        let block = try await client!.eth_getBlockByNumber(.number(0))
        XCTAssertEqual(block.timestamp.timeIntervalSince1970, 0)
        XCTAssertEqual(block.transactions.count, 0)
        XCTAssertEqual(block.number, .number(0))
    }

    func testGivenLatestBlock_ThenReturnsByNumber() async throws {
        let block = try await client!.eth_getBlockByNumber(.latest)
        XCTAssert(block.number.intValue ?? 0 > 1)
    }

    func testGivenExistingBlock_ThenGetsBlockByNumber() async throws {
        let block = try await client!.eth_getBlockByNumber(.number(3415757))
        XCTAssertEqual(block.number, .number(3415757))
        XCTAssertEqual(block.timestamp.timeIntervalSince1970, 1528711895)
        XCTAssertEqual(block.transactions.count, 40)
        XCTAssertEqual(block.transactions.first, "0x387867d052b3f89fb87937572891118aa704c1ba604c157bbd9c5a07f3a7e5cd")
    }

    func testGivenUnexistingBlockNumber_ThenGetBlockByNumberReturnsError() async {
        let expectation = XCTestExpectation(description: "get block by number")

        do {
            _ = try await client!.eth_getBlockByNumber(.number(Int.max))
            XCTFail("fail: block should not exist")
        } catch {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: timeout)
    }

    func testGivenNoFilters_WhenMatchingSingleTransferEvents_AllEventsReturned() async throws {
        let to = try! ABIEncoder.encode(EthereumAddress("0x3C1Bd6B420448Cf16A389C8b0115CCB3660bB854"))
        let (events, logs) = try await client!.getEvents(
            addresses: nil,
            topics: [try! ERC20Events.Transfer.signature(), nil, to.hexString, nil],
            fromBlock: .earliest,
            toBlock: .latest,
            eventTypes: [ERC20Events.Transfer.self])
        
        XCTAssertEqual(events.count, 2)
        XCTAssertEqual(logs.count, 0)
    }

    func testGivenNoFilters_WhenMatchingMultipleTransferEvents_BothEventsReturned() async throws {
        let to = try! ABIEncoder.encode(EthereumAddress("0x3C1Bd6B420448Cf16A389C8b0115CCB3660bB854"))
        let (events, logs) = try await client!.getEvents(addresses: nil,
                      topics: [try! ERC20Events.Transfer.signature(), nil, to.hexString, nil],
                      fromBlock: .earliest,
                      toBlock: .latest,
                      eventTypes: [ERC20Events.Transfer.self, TransferMatchingSignatureEvent.self])
    
        XCTAssertEqual(events.count, 4)
        XCTAssertEqual(logs.count, 0)
    }

    func testGivenContractFilter_WhenMatchingSingleTransferEvents_OnlyMatchingSourceEventReturned() async throws {
        let to = try! ABIEncoder.encodeRaw("0x3C1Bd6B420448Cf16A389C8b0115CCB3660bB854", forType: ABIRawType.FixedAddress)
        let filters = [
            EventFilter(type: ERC20Events.Transfer.self, allowedSenders: [EthereumAddress("0xdb0040451f373949a4be60dcd7b6b8d6e42658b6")])
        ]
        let (events, logs) = try await client!.getEvents(addresses: nil,
                          topics: [try! ERC20Events.Transfer.signature(), nil, to.hexString, nil],
                          fromBlock: .earliest,
                          toBlock: .latest,
                          matching: filters)
        
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(logs.count, 1)
    }

    func testGivenContractFilter_WhenMatchingMultipleTransferEvents_OnlyMatchingSourceEventsReturned() async throws {
        let to = try! ABIEncoder.encode(EthereumAddress("0x3C1Bd6B420448Cf16A389C8b0115CCB3660bB854"))
        let filters = [
            EventFilter(type: ERC20Events.Transfer.self, allowedSenders: [EthereumAddress("0xdb0040451f373949a4be60dcd7b6b8d6e42658b6")]),
            EventFilter(type: TransferMatchingSignatureEvent.self, allowedSenders: [EthereumAddress("0xdb0040451f373949a4be60dcd7b6b8d6e42658b6")])
        ]
        let (events, logs) = try await client!.getEvents(addresses: nil,
                                                         topics: [try! ERC20Events.Transfer.signature(), nil, to.hexString, nil],
                                                         fromBlock: .earliest,
                                                         toBlock: .latest,
                                                         matching: filters)
       XCTAssertEqual(events.count, 2)
       XCTAssertEqual(logs.count, 2)
    }

    func test_GivenDynamicArrayResponse_ThenCallReceivesData() async throws {
        let function = GetGuardians(wallet: EthereumAddress("0x2A6295C34b4136F2C3c1445c6A0338D784fe0ddd"))
        let response = try await function.call(withClient: self.client!, responseType: GetGuardians.Response.self)
        XCTAssertEqual(response.guardians, [EthereumAddress("0x44fe11c90d2bcbc8267a0e56d55235ddc2b96c4f")])
    }

    // This is how geth used to work up until a recent version
    // see https://github.com/ethereum/go-ethereum/pull/21083/
    // Used to return '0x' in response, and would fail decoding
    // We'll continue to support this as user of library (and Argent in our case)
    // works with this assumption.
    // NOTE: This behaviour will be removed at a later time to fail as expected
    // NOTE: At the time of writing, this test succeeds as-is in ropsten as nodes behaviour is different. That's why we use a mainnet check here
    func test_GivenUnimplementedMethod_WhenCallingContract_ThenFailsWith0x() async {
        let expectation = expectation(description: "graceful_failure")

        let function = InvalidMethodA(param: .zero)

        do {
            _ = try await function.call(withClient: self.mainnetClient!, responseType: InvalidMethodA.BoolResponse.self)
            XCTFail("this call should fail")
        } catch {
            XCTAssertEqual(error as? Web3Error, Web3Error.decodeIssue )
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: timeout)
    }
    
    func test_GivenFailingCallMethod_WhenCallingContract_ThenFailsWith0x() async {
        let expectation = expectation(description: "graceful_failure")

        let function = InvalidMethodB(param: .zero)

        do {
            _ = try await function.call(withClient: self.mainnetClient!, responseType: InvalidMethodB.BoolResponse.self)
            XCTFail("this call should fail")
        } catch {
            XCTAssertEqual(error as? Web3Error, Web3Error.decodeIssue )
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: timeout)
    }

}
