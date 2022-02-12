//
//  EthereumClientTests.swift
//  web3sTests
//
//  Created by Matt Marshall on 09/03/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import XCTest
@testable import web3
import BigInt

struct TransferMatchingSignatureEvent: ABIEvent {
    public static let name = "Transfer"
    public static let types: [ABIType.Type] = [ EthereumAddress.self , EthereumAddress.self , BigUInt.self]
    public static let typesIndexed = [true, true, false]
    public let log: EthereumLog

    public let from: EthereumAddress
    public let to: EthereumAddress
    public let value: BigUInt

    public init?(topics: [ABIDecoder.DecodedValue], data: [ABIDecoder.DecodedValue], log: EthereumLog) throws {
        try TransferMatchingSignatureEvent.checkParameters(topics, data)
        self.log = log

        self.from = try topics[0].decoded()
        self.to = try topics[1].decoded()

        self.value = try data[0].decoded()
    }
}


class EthereumClientTests: XCTestCase {
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

    func testEthGetBalance() {
        let expectation = XCTestExpectation(description: "get remote balance")
        client?.eth_getBalance(address: account?.address ?? .zero, block: .Latest, completion: { (error, balance) in
            XCTAssertNotNil(balance, "Balance not available: \(error?.localizedDescription ?? "no error")")
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: timeout)
    }

    func testEthGetBalanceIncorrectAddress() {
        let expectation = XCTestExpectation(description: "get remote balance incorrect")

        client?.eth_getBalance(address: EthereumAddress("0xnig42niog2"), block: .Latest, completion: { (error, balance) in
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
        client?.eth_getCode(address: EthereumAddress("0x112234455c3a32fd11230c42e7bccd4a84e02010"), completion: { (error, code) in
            XCTAssertNotNil(code, "Contract code not available: \(error?.localizedDescription ?? "no error")")
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: timeout)
    }

    func testEthSendRawTransaction() {
        let expectation = XCTestExpectation(description: "send raw transaction")

        let tx = EthereumTransaction(from: nil, to: EthereumAddress("0x3c1bd6b420448cf16a389c8b0115ccb3660bb854"), value: BigUInt(1600000), data: nil, nonce: 2, gasPrice: BigUInt(40000000), gasLimit: BigUInt(500000), chainId: EthereumNetwork.Ropsten.intValue)

        self.client?.eth_sendRawTransaction(tx, withAccount: self.account!, completion: { (error, txHash) in
            XCTAssertNotNil(txHash, "No tx hash, ensure key is valid in TestConfig.swift")
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

    func testSimpleEthGetLogs() {
        let expectation = XCTestExpectation(description: "get logs")

        client?.eth_getLogs(addresses: [EthereumAddress("0x23d0a442580c01e420270fba6ca836a8b2353acb")], topics: nil, fromBlock: .Earliest, toBlock: .Latest, completion: { (error, logs) in
            XCTAssertNotNil(logs, "Logs not available \(error?.localizedDescription ?? "no error")")
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: timeout)
    }

    func testOrTopicsEthGetLogs() {
        let expectation = XCTestExpectation(description: "get logs")

        // Deposit/Withdrawal event to specific address
        client?.eth_getLogs(addresses: nil, orTopics: [["0xe1fffcc4923d04b559f4d29a8bfc6cda04eb5b0d3c460751c2402c5c5cc9109c", "0x7fcf532c15f0a6db0bd6d0e038bea71d30d808c7d98cb3bf7268a95bf5081b65"], ["0x000000000000000000000000655ef694b98e55977a93259cb3b708560869a8f3"]], fromBlock: .Number(6540313), toBlock: .Number(6540397), completion: { (error, logs) in
            XCTAssertEqual(logs?.count, 2)
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
            XCTAssertNotNil(block?.number.intValue)
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

        let to = try! ABIEncoder.encode(EthereumAddress("0x3C1Bd6B420448Cf16A389C8b0115CCB3660bB854"))

        client?.getEvents(addresses: nil,
                          topics: [try! ERC20Events.Transfer.signature(), nil, to.hexString, nil],
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

        let to = try! ABIEncoder.encode(EthereumAddress("0x3C1Bd6B420448Cf16A389C8b0115CCB3660bB854"))

        client?.getEvents(addresses: nil,
                          topics: [try! ERC20Events.Transfer.signature(), nil, to.hexString, nil],
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

        let to = try! ABIEncoder.encodeRaw("0x3C1Bd6B420448Cf16A389C8b0115CCB3660bB854", forType: ABIRawType.FixedAddress)
        let filters = [
            EventFilter(type: ERC20Events.Transfer.self, allowedSenders: [EthereumAddress("0xdb0040451f373949a4be60dcd7b6b8d6e42658b6")])
        ]

        client?.getEvents(addresses: nil,
                          topics: [try! ERC20Events.Transfer.signature(), nil, to.hexString, nil],
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

        let to = try! ABIEncoder.encode(EthereumAddress("0x3C1Bd6B420448Cf16A389C8b0115CCB3660bB854"))
        let filters = [
            EventFilter(type: ERC20Events.Transfer.self, allowedSenders: [EthereumAddress("0xdb0040451f373949a4be60dcd7b6b8d6e42658b6")]),
            EventFilter(type: TransferMatchingSignatureEvent.self, allowedSenders: [EthereumAddress("0xdb0040451f373949a4be60dcd7b6b8d6e42658b6")])
        ]

        client?.getEvents(addresses: nil,
                          topics: [try! ERC20Events.Transfer.signature(), nil, to.hexString, nil],
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

    func test_GivenDynamicArrayResponse_ThenCallReceivesData() {
        let expect = expectation(description: "call")

        let function = GetGuardians(wallet: EthereumAddress("0x2A6295C34b4136F2C3c1445c6A0338D784fe0ddd"))
        function.call(withClient: self.client!,
                      responseType: GetGuardians.Response.self) { (error, response) in
            XCTAssertNil(error)
            XCTAssertEqual(response?.guardians, [EthereumAddress("0x44fe11c90d2bcbc8267a0e56d55235ddc2b96c4f")])
            expect.fulfill()
        }

        waitForExpectations(timeout: 10)
    }

    // This is how geth used to work up until a recent version
    // see https://github.com/ethereum/go-ethereum/pull/21083/
    // Used to return '0x' in response, and would fail decoding
    // We'll continue to support this as user of library (and Argent in our case)
    // works with this assumption.
    // NOTE: This behaviour will be removed at a later time to fail as expected
    // NOTE: At the time of writing, this test succeeds as-is in ropsten as nodes behaviour is different. That's why we use a mainnet check here
    func test_GivenUnimplementedMethod_WhenCallingContract_ThenFailsWith0x() {
        let expect = expectation(description: "graceful_failure")

        let function = InvalidMethodA(param: .zero)

        function.call(withClient: self.mainnetClient!,
                      responseType: InvalidMethodA.BoolResponse.self) { (error, response) in
            XCTAssertEqual(error, .decodeIssue)
            XCTAssertNil(response)
            expect.fulfill()
        }

        waitForExpectations(timeout: 10)
    }
    func test_GivenFailingCallMethod_WhenCallingContract_ThenFailsWith0x() {
        let expect = expectation(description: "graceful_failure")

        let function = InvalidMethodB(param: .zero)

        function.call(withClient: self.mainnetClient!,
                      responseType: InvalidMethodB.BoolResponse.self) { (error, response) in
            XCTAssertEqual(error, .decodeIssue)
            XCTAssertNil(response)
            expect.fulfill()
        }

        waitForExpectations(timeout: 10)
    }

    func test_GivenValidTransaction_ThenEstimatesGas() {
        let expect = expectation(description: "estimateOK")
        let function = TransferToken(wallet: EthereumAddress("0xD18dE36e6FB4a5A069f673723Fab71cc00C6CE5F"),
                                     token: EthereumAddress("0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"),
                                     to: EthereumAddress("0x2A6295C34b4136F2C3c1445c6A0338D784fe0ddd"),
                                     amount: 1,
                                     data: Data(),
                                     gasPrice: 0,
                                     gasLimit: 0)
        client!.eth_estimateGas(try! function.transaction(), withAccount: account!) { (error, value) in
            XCTAssertNil(error)
            XCTAssert(value != 0)
            expect.fulfill()
        }

        waitForExpectations(timeout: 10)
    }
}

#if compiler(>=5.5) && canImport(_Concurrency)

@available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
extension EthereumClientTests {
    func testEthGetBalance_Async() async throws {
        do {
            let balance = try await client?.eth_getBalance(address: account?.address ?? .zero, block: .Latest)
            XCTAssertNotNil(balance, "Balance not available")
        } catch {
            XCTFail("Expected balance but failed \(error).")
        }
    }

    func testEthGetBalanceIncorrectAddress_Async() async {
        do {
            _ = try await client?.eth_getBalance(address: EthereumAddress("0xnig42niog2"), block: .Latest)
            XCTFail("Expected to throw while awaiting, but succeeded")
        } catch {
            XCTAssertEqual(error as? EthereumClientError, .unexpectedReturnValue)
        }
    }

    func testNetVersion_Async() async {
        do {
            let network = try await client?.net_version()
            XCTAssertEqual(network, EthereumNetwork.Ropsten, "Network incorrect")
        } catch {
            XCTFail("Expected network but failed \(error).")
        }
    }

    func testEthGasPrice_Async() async {
        do {
            let gas = try await client?.eth_gasPrice()
            XCTAssertNotNil(gas, "Gas not available")
        } catch {
            XCTFail("Expected gas but failed \(error).")
        }
    }

    func testEthBlockNumber_Async() async {
        do {
            let block = try await client?.eth_blockNumber()
            XCTAssertNotNil(block, "Block not available")
        } catch {
            XCTFail("Expected blockNumber but failed \(error).")
        }
    }

    func testEthGetCode_Async() async {
        do {
            let code = try await client?.eth_getCode(address: EthereumAddress("0x112234455c3a32fd11230c42e7bccd4a84e02010"))
            XCTAssertNotNil(code, "Contract code not available")
        } catch {
            XCTFail("Expected code but failed \(error).")
        }
    }

    func testEthSendRawTransaction_Async() async {
        do {
            let tx = EthereumTransaction(from: nil, to: EthereumAddress("0x3c1bd6b420448cf16a389c8b0115ccb3660bb854"), value: BigUInt(1600000), data: nil, nonce: 2, gasPrice: BigUInt(4000000), gasLimit: BigUInt(50000), chainId: EthereumNetwork.Ropsten.intValue)

            let txHash = try await client?.eth_sendRawTransaction(tx, withAccount: self.account!)
            XCTAssertNotNil(txHash, "No tx hash, ensure key is valid in TestConfig.swift")
        } catch {
            XCTFail("Expected tx but failed \(error).")
        }
    }

    func testEthGetTransactionCount_Async() async {
        do {
            let count = try await client?.eth_getTransactionCount(address: account!.address, block: .Latest)
            XCTAssertNotNil(count, "Transaction count not available")
        } catch {
            XCTFail("Expected count but failed \(error).")
        }
    }

    func testEthGetTransactionCountPending_Async() async {
        do {
            let count = try await client?.eth_getTransactionCount(address: account!.address, block: .Pending)
            XCTAssertNotNil(count, "Transaction count not available")
        } catch {
            XCTFail("Expected count but failed \(error).")
        }
    }

    func testEthGetTransactionReceipt_Async() async {
        do {
            let txHash = "0xc51002441dc669ad03697fd500a7096c054b1eb2ce094821e68831a3666fc878"
            let receipt = try await client?.eth_getTransactionReceipt(txHash: txHash)
            XCTAssertNotNil(receipt, "Transaction receipt not available")
        } catch {
            XCTFail("Expected receipt but failed \(error).")
        }
    }

    func testEthCall_Async() async {
        do {
            let tx = EthereumTransaction(from: nil, to: EthereumAddress("0x3c1bd6b420448cf16a389c8b0115ccb3660bb854"), value: BigUInt(1800000), data: nil, nonce: 2, gasPrice: BigUInt(400000), gasLimit: BigUInt(50000), chainId: EthereumNetwork.Ropsten.intValue)
            let txHash = try await client?.eth_call(tx, block: .Latest)
            XCTAssertNotNil(txHash, "Transaction hash not available")
        } catch {
            XCTFail("Expected txHash but failed \(error).")
        }
    }

    func testSimpleEthGetLogs_Async() async {
        do {
            let logs = try await client?.eth_getLogs(addresses: [EthereumAddress("0x23d0a442580c01e420270fba6ca836a8b2353acb")], topics: nil, fromBlock: .Earliest, toBlock: .Latest)
            XCTAssertNotNil(logs, "Logs not available")
        } catch {
            XCTFail("Expected logs but failed \(error).")
        }
    }

    func testOrTopicsEthGetLogs_Async() async {
        do {
            let logs = try await client?.eth_getLogs(addresses: nil, orTopics: [["0xe1fffcc4923d04b559f4d29a8bfc6cda04eb5b0d3c460751c2402c5c5cc9109c", "0x7fcf532c15f0a6db0bd6d0e038bea71d30d808c7d98cb3bf7268a95bf5081b65"], ["0x000000000000000000000000655ef694b98e55977a93259cb3b708560869a8f3"]], fromBlock: .Number(6540313), toBlock: .Number(6540397))
            XCTAssertEqual(logs?.count, 2)
            XCTAssertNotNil(logs, "Logs not available")
        } catch {
            XCTFail("Expected logs but failed \(error).")
        }
    }

    func testGivenGenesisBlock_ThenReturnsByNumber_Async() async {
        do {
            let block = try await client?.eth_getBlockByNumber(.Number(0))
            XCTAssertEqual(block?.timestamp.timeIntervalSince1970, 0)
            XCTAssertEqual(block?.transactions.count, 0)
            XCTAssertEqual(block?.number, .Number(0))
        } catch {
            XCTFail("Expected block but failed \(error).")
        }
    }

    func testGivenLatestBlock_ThenReturnsByNumber_Async() async {
        do {
            let block = try await client?.eth_getBlockByNumber(.Latest)
            XCTAssertNotNil(block?.number.intValue)
        } catch {
            XCTFail("Expected block but failed \(error).")
        }
    }

    func testGivenExistingBlock_ThenGetsBlockByNumber_Async() async {
        do {
            let block = try await client?.eth_getBlockByNumber(.Number(3415757))
            XCTAssertEqual(block?.number, .Number(3415757))
            XCTAssertEqual(block?.timestamp.timeIntervalSince1970, 1528711895)
            XCTAssertEqual(block?.transactions.count, 40)
            XCTAssertEqual(block?.transactions.first, "0x387867d052b3f89fb87937572891118aa704c1ba604c157bbd9c5a07f3a7e5cd")
        } catch {
            XCTFail("Expected block but failed \(error).")
        }
    }

    func testGivenUnexistingBlockNumber_ThenGetBlockByNumberReturnsError_Async() async {
        do {
            let _ = try await client?.eth_getBlockByNumber(.Number(Int.max))
            XCTFail("Expected to throw while awaiting, but succeeded")
        } catch {
            XCTAssertEqual(error as? EthereumClientError, .unexpectedReturnValue)
        }
    }

    func testGivenMinedTransactionHash_ThenGetsTransactionByHash_Async() async {
        do {
            let transaction = try await client?.eth_getTransaction(byHash: "0x014726c783ab2fd6828a9ca556850bccfc66f70926f411274eaf886385c704af")
            XCTAssertEqual(transaction?.from?.value, "0xbbf5029fd710d227630c8b7d338051b8e76d50b3")
            XCTAssertEqual(transaction?.to.value, "0x37f13b5ffcc285d2452c0556724afb22e58b6bbe")
            XCTAssertEqual(transaction?.gas, "30400")
            XCTAssertEqual(transaction?.gasPrice, BigUInt(hex: "0x9184e72a000"))
            XCTAssertEqual(transaction?.nonce, 973253)
            XCTAssertEqual(transaction?.value, BigUInt(hex: "0x56bc75e2d63100000"))
            XCTAssertEqual(transaction?.blockNumber, EthereumBlock.Number(3439303))
            XCTAssertEqual(transaction?.hash?.web3.hexString, "0x014726c783ab2fd6828a9ca556850bccfc66f70926f411274eaf886385c704af")
        } catch {
            XCTFail("Expected transaction but failed \(error).")
        }
    }

    func testGivenUnexistingTransactionHash_ThenErrorsGetTransactionByHash_Async() async {
        do {
            let _ = try await client?.eth_getTransaction(byHash: "0x01234")
            XCTFail("Expected to throw while awaiting, but succeeded")
        } catch {
            XCTAssertEqual(error as? EthereumClientError, .unexpectedReturnValue)
        }
    }

    func testGivenNoFilters_WhenMatchingSingleTransferEvents_AllEventsReturned_Async() async {
        do {
            let to = try! ABIEncoder.encode(EthereumAddress("0x3C1Bd6B420448Cf16A389C8b0115CCB3660bB854"))

            let eventsResult = try await client?.getEvents(addresses: nil,
                                                           topics: [try! ERC20Events.Transfer.signature(), nil, to.hexString, nil],
                                                           fromBlock: .Earliest,
                                                           toBlock: .Latest,
                                                           eventTypes: [ERC20Events.Transfer.self])
            XCTAssertEqual(eventsResult?.events.count, 2)
            XCTAssertEqual(eventsResult?.logs.count, 0)
        } catch {
            XCTFail("Expected events but failed \(error).")
        }
    }

    func testGivenNoFilters_WhenMatchingMultipleTransferEvents_BothEventsReturned_Async() async {
        do {
            let to = try! ABIEncoder.encode(EthereumAddress("0x3C1Bd6B420448Cf16A389C8b0115CCB3660bB854"))

            let eventsResult = try await client?.getEvents(addresses: nil,
                                                           topics: [try! ERC20Events.Transfer.signature(), nil, to.hexString, nil],
                                                           fromBlock: .Earliest,
                                                           toBlock: .Latest,
                                                           eventTypes: [ERC20Events.Transfer.self, TransferMatchingSignatureEvent.self])
            XCTAssertEqual(eventsResult?.events.count, 4)
            XCTAssertEqual(eventsResult?.logs.count, 0)
        } catch {
            XCTFail("Expected events but failed \(error).")
        }
    }

    func testGivenContractFilter_WhenMatchingSingleTransferEvents_OnlyMatchingSourceEventReturned_Async() async {
        do {
            let to = try! ABIEncoder.encodeRaw("0x3C1Bd6B420448Cf16A389C8b0115CCB3660bB854", forType: ABIRawType.FixedAddress)
            let filters = [
                EventFilter(type: ERC20Events.Transfer.self, allowedSenders: [EthereumAddress("0xdb0040451f373949a4be60dcd7b6b8d6e42658b6")])
            ]

            let eventsResult = try await client?.getEvents(addresses: nil,
                                                           topics: [try! ERC20Events.Transfer.signature(), nil, to.hexString, nil],
                                                           fromBlock: .Earliest,
                                                           toBlock: .Latest,
                                                           matching: filters)
            XCTAssertEqual(eventsResult?.events.count, 1)
            XCTAssertEqual(eventsResult?.logs.count, 1)
        } catch {
            XCTFail("Expected events but failed \(error).")
        }
    }

    func testGivenContractFilter_WhenMatchingMultipleTransferEvents_OnlyMatchingSourceEventsReturned_Async() async {
        do {
            let to = try! ABIEncoder.encode(EthereumAddress("0x3C1Bd6B420448Cf16A389C8b0115CCB3660bB854"))
            let filters = [
                EventFilter(type: ERC20Events.Transfer.self, allowedSenders: [EthereumAddress("0xdb0040451f373949a4be60dcd7b6b8d6e42658b6")]),
                EventFilter(type: TransferMatchingSignatureEvent.self, allowedSenders: [EthereumAddress("0xdb0040451f373949a4be60dcd7b6b8d6e42658b6")])
            ]

            let eventsResult = try await client?.getEvents(addresses: nil,
                                                           topics: [try! ERC20Events.Transfer.signature(), nil, to.hexString, nil],
                                                           fromBlock: .Earliest,
                                                           toBlock: .Latest,
                                                           matching: filters)
            XCTAssertEqual(eventsResult?.events.count, 2)
            XCTAssertEqual(eventsResult?.logs.count, 2)
        } catch {
            XCTFail("Expected events but failed \(error).")
        }
    }

    func test_GivenDynamicArrayResponse_ThenCallReceivesData_Async() async {
        do {
            let function = GetGuardians(wallet: EthereumAddress("0x2A6295C34b4136F2C3c1445c6A0338D784fe0ddd"))

            let response = try await function.call(withClient: self.client!, responseType: GetGuardians.Response.self)
            XCTAssertEqual(response.guardians, [EthereumAddress("0x44fe11c90d2bcbc8267a0e56d55235ddc2b96c4f")])
        } catch {
            XCTFail("Expected response but failed \(error).")
        }
    }

    // This is how geth used to work up until a recent version
    // see https://github.com/ethereum/go-ethereum/pull/21083/
    // Used to return '0x' in response, and would fail decoding
    // We'll continue to support this as user of library (and Argent in our case)
    // works with this assumption.
    // NOTE: This behaviour will be removed at a later time to fail as expected
    // NOTE: At the time of writing, this test succeeds as-is in ropsten as nodes behaviour is different. That's why we use a mainnet check here
    func test_GivenUnimplementedMethod_WhenCallingContract_ThenFailsWith0x_Async() async {
        do {
            let function = InvalidMethodA(param: .zero)
            let _ = try await function.call(withClient: self.mainnetClient!,
                                            responseType: InvalidMethodA.BoolResponse.self)
            XCTFail("Expected to throw while awaiting, but succeeded")
        } catch {
            XCTAssertEqual(error as? EthereumClientError, .decodeIssue)
        }
    }

    func test_GivenFailingCallMethod_WhenCallingContract_ThenFailsWith0x_Async() async {
        do {
            let function = InvalidMethodB(param: .zero)
            let _ = try await function.call(withClient: self.mainnetClient!,
                                            responseType: InvalidMethodB.BoolResponse.self)
            XCTFail("Expected to throw while awaiting, but succeeded")
        } catch {
            XCTAssertEqual(error as? EthereumClientError, .decodeIssue)
        }
    }

    func test_GivenValidTransaction_ThenEstimatesGas_Async() async {
        do {
            let function = TransferToken(wallet: EthereumAddress("0xD18dE36e6FB4a5A069f673723Fab71cc00C6CE5F"),
                                         token: EthereumAddress("0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"),
                                         to: EthereumAddress("0x2A6295C34b4136F2C3c1445c6A0338D784fe0ddd"),
                                         amount: 1,
                                         data: Data(),
                                         gasPrice: 0,
                                         gasLimit: 0)

            let value = try await client!.eth_estimateGas(try! function.transaction(), withAccount: account!)
            XCTAssert(value != 0)
        } catch {
            XCTFail("Expected value but failed \(error).")
        }
    }
}

#endif

struct GetGuardians: ABIFunction {
    static let name = "getGuardians"
    let contract = EthereumAddress("0x25BD64224b7534f7B9e3E16dd10b6dED1A412b90")
    let from: EthereumAddress? = EthereumAddress("0x25BD64224b7534f7B9e3E16dd10b6dED1A412b90")
    let gasPrice: BigUInt? = nil
    let gasLimit: BigUInt? = nil

    struct Response: ABIResponse {
        static var types: [ABIType.Type] = [ABIArray<EthereumAddress>.self]
        let guardians: [EthereumAddress]

        init?(values: [ABIDecoder.DecodedValue]) throws {
            self.guardians = try values[0].decodedArray()

        }
    }

    let wallet: EthereumAddress

    func encode(to encoder: ABIFunctionEncoder) throws {
        try encoder.encode(wallet)

    }
}

struct TransferToken: ABIFunction {
    static let name = "transferToken"
    let contract = EthereumAddress("0xe4f5384d96cc4e6929b63546082788906250b60b")
    let from: EthereumAddress? = EthereumAddress("0xe4f5384d96cc4e6929b63546082788906250b60b")

    let wallet: EthereumAddress
    let token: EthereumAddress
    let to: EthereumAddress
    let amount: BigUInt
    let data: Data

    let gasPrice: BigUInt?
    let gasLimit: BigUInt?

    func encode(to encoder: ABIFunctionEncoder) throws {
        try encoder.encode(wallet)
        try encoder.encode(token)
        try encoder.encode(to)
        try encoder.encode(amount)
        try encoder.encode(data)
    }
}

struct InvalidMethodA: ABIFunction {
    static let name = "invalidMethodCallBoolResponse"
    let contract = EthereumAddress("0xed0439eacf4c4965ae4613d77a5c2efe10e5f183")
    let from: EthereumAddress? = EthereumAddress("0xed0439eacf4c4965ae4613d77a5c2efe10e5f183")
    let gasPrice: BigUInt? = nil
    let gasLimit: BigUInt? = nil

    let param: EthereumAddress

    struct BoolResponse: ABIResponse {
        static var types: [ABIType.Type] = [Bool.self]
        let value: Bool

        init?(values: [ABIDecoder.DecodedValue]) throws {
            self.value = try values[0].decoded()
        }
    }

    func encode(to encoder: ABIFunctionEncoder) throws {
    }
}

struct InvalidMethodB: ABIFunction {
    static let name = "invalidMethodCallBoolResponse"
    let contract = EthereumAddress("0xC011A72400E58ecD99Ee497CF89E3775d4bd732F")
    let from: EthereumAddress? = EthereumAddress("0xC011A72400E58ecD99Ee497CF89E3775d4bd732F")
    let gasPrice: BigUInt? = nil
    let gasLimit: BigUInt? = nil

    let param: EthereumAddress

    struct BoolResponse: ABIResponse {
        static var types: [ABIType.Type] = [Bool.self]
        let value: Bool

        init?(values: [ABIDecoder.DecodedValue]) throws {
            self.value = try values[0].decoded()
        }
    }

    func encode(to encoder: ABIFunctionEncoder) throws {
    }
}
