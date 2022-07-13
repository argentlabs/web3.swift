//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import BigInt
import NIO
import XCTest
@testable import web3

struct TransferMatchingSignatureEvent: ABIEvent {
    public static let name = "Transfer"
    public static let types: [ABIType.Type] = [ EthereumAddress.self, EthereumAddress.self, BigUInt.self]
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
    var client: EthereumClientProtocol?
    var account: EthereumAccount?
    
    override func setUp() {
        super.setUp()
        client = EthereumHttpClient(url: URL(string: TestConfig.clientUrl)!)
        account = try? EthereumAccount(keyStorage: TestEthereumKeyStorage(privateKey: TestConfig.privateKey))
        print("Public address: \(account?.address.value ?? "NONE")")
    }

    func testEthGetTransactionCount() async {
        do {
            let count = try await client?.eth_getTransactionCount(address: account!.address, block: .Latest)
            XCTAssertNotEqual(count, 0)
        } catch {
            XCTFail("Expected count but failed \(error).")
        }
    }

    func testEthGetTransactionCountPending() async {
        do {
            let count = try await client?.eth_getTransactionCount(address: account!.address, block: .Pending)
            XCTAssertNotEqual(count, 0)
        } catch {
            XCTFail("Expected count but failed \(error).")
        }
    }

    func testEthGetBalance() async throws {
        do {
            let balance = try await client?.eth_getBalance(address: account?.address ?? .zero, block: .Latest)
            XCTAssertNotNil(balance, "Balance not available")
        } catch {
            XCTFail("Expected balance but failed \(error).")
        }
    }

    func testEthGetBalanceIncorrectAddress() async {
        do {
            _ = try await client?.eth_getBalance(address: "0xnig42niog2", block: .Latest)
            XCTFail("Expected to throw while awaiting, but succeeded")
        } catch {
            XCTAssertEqual(error as? EthereumClientError, .executionError(
                .init(code: -32602, message: "invalid argument 0: hex string has length 10, want 40 for common.Address", data: nil)
            ))
        }
    }

    func testNetVersion() async {
        do {
            let network = try await client?.net_version()
            XCTAssertEqual(network, EthereumNetwork.ropsten, "Network incorrect")
        } catch {
            XCTFail("Expected network but failed \(error).")
        }
    }

    func testEthGasPrice() async {
        do {
            let gas = try await client?.eth_gasPrice()
            XCTAssertNotNil(gas, "Gas not available")
        } catch {
            XCTFail("Expected gas but failed \(error).")
        }
    }

    func testEthBlockNumber() async {
        do {
            let block = try await client?.eth_blockNumber()
            XCTAssertNotNil(block, "Block not available")
        } catch {
            XCTFail("Expected blockNumber but failed \(error).")
        }
    }

    func testEthGetCode() async {
        do {
            let code = try await client?.eth_getCode(address: "0x112234455c3a32fd11230c42e7bccd4a84e02010", block: .Latest)
            XCTAssertNotNil(code, "Contract code not available")
        } catch {
            XCTFail("Expected code but failed \(error).")
        }
    }

    func testEthSendRawTransaction() async {
        do {
            let tx = EthereumTransaction(from: nil, to: "0x3c1bd6b420448cf16a389c8b0115ccb3660bb854", value: BigUInt(1600000), data: nil, nonce: 2, gasPrice: BigUInt(4000000), gasLimit: BigUInt(500000), chainId: EthereumNetwork.ropsten.intValue)

            let txHash = try await client?.eth_sendRawTransaction(tx, withAccount: account!)
            XCTAssertNotNil(txHash, "No tx hash, ensure key is valid in TestConfig.swift")
        } catch {
            XCTFail("Expected tx but failed \(error).")
        }
    }

    func testEthGetTransactionReceipt() async {
        do {
            let txHash = "0xc51002441dc669ad03697fd500a7096c054b1eb2ce094821e68831a3666fc878"
            let receipt = try await client?.eth_getTransactionReceipt(txHash: txHash)
            XCTAssertNotNil(receipt, "Transaction receipt not available")
        } catch {
            XCTFail("Expected receipt but failed \(error).")
        }
    }

    func testEthCall() async {
        do {
            let tx = EthereumTransaction(from: nil, to: "0x3c1bd6b420448cf16a389c8b0115ccb3660bb854", value: BigUInt(1800000), data: nil, nonce: 2, gasPrice: BigUInt(400000), gasLimit: BigUInt(50000), chainId: EthereumNetwork.ropsten.intValue)
            let txHash = try await client?.eth_call(tx, block: .Latest)
            XCTAssertNotNil(txHash, "Transaction hash not available")
        } catch {
            XCTFail("Expected txHash but failed \(error).")
        }
    }

    func testSimpleEthGetLogs() async {
        do {
            let logs = try await client?.eth_getLogs(addresses: ["0x23d0a442580c01e420270fba6ca836a8b2353acb"], topics: nil, fromBlock: .Earliest, toBlock: .Latest)
            XCTAssertNotNil(logs, "Logs not available")
        } catch {
            XCTFail("Expected logs but failed \(error).")
        }
    }

    func testOrTopicsEthGetLogs() async {
        do {
            let logs = try await client?.eth_getLogs(addresses: nil, orTopics: [["0xe1fffcc4923d04b559f4d29a8bfc6cda04eb5b0d3c460751c2402c5c5cc9109c", "0x7fcf532c15f0a6db0bd6d0e038bea71d30d808c7d98cb3bf7268a95bf5081b65"], ["0x000000000000000000000000655ef694b98e55977a93259cb3b708560869a8f3"]], fromBlock: .Number(6540313), toBlock: .Number(6540397))
            XCTAssertEqual(logs?.count, 2)
            XCTAssertNotNil(logs, "Logs not available")
        } catch {
            XCTFail("Expected logs but failed \(error).")
        }
    }

    func testGivenGenesisBlock_ThenReturnsByNumber() async {
        do {
            let block = try await client?.eth_getBlockByNumber(.Number(0))
            XCTAssertEqual(block?.timestamp.timeIntervalSince1970, 0)
            XCTAssertEqual(block?.transactions.count, 0)
            XCTAssertEqual(block?.number, .Number(0))
        } catch {
            XCTFail("Expected block but failed \(error).")
        }
    }

    func testGivenLatestBlock_ThenReturnsByNumber() async {
        do {
            let block = try await client?.eth_getBlockByNumber(.Latest)
            XCTAssertNotNil(block?.number.intValue)
        } catch {
            XCTFail("Expected block but failed \(error).")
        }
    }

    func testGivenExistingBlock_ThenGetsBlockByNumber() async {
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

    func testGivenUnexistingBlockNumber_ThenGetBlockByNumberReturnsError() async {
        do {
            _ = try await client?.eth_getBlockByNumber(.Number(Int.max))
            XCTFail("Expected to throw while awaiting, but succeeded")
        } catch {
            XCTAssertEqual(error as? EthereumClientError, .unexpectedReturnValue)
        }
    }

    func testGivenMinedTransactionHash_ThenGetsTransactionByHash() async {
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

    func testGivenUnexistingTransactionHash_ThenErrorsGetTransactionByHash() async {
        do {
            _ = try await client?.eth_getTransaction(byHash: "0x01234")
            XCTFail("Expected to throw while awaiting, but succeeded")
        } catch {
            XCTAssertEqual(error as? EthereumClientError, .executionError(
                .init(code: -32602, message: "invalid argument 0: json: cannot unmarshal hex string of odd length into Go value of type common.Hash", data: nil)
            ))
        }
    }

    func testGivenNoFilters_WhenMatchingSingleTransferEvents_AllEventsReturned() async {
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

    func testGivenNoFilters_WhenMatchingMultipleTransferEvents_BothEventsReturned() async {
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

    func testGivenContractFilter_WhenMatchingSingleTransferEvents_OnlyMatchingSourceEventReturned() async {
        do {
            let to = try! ABIEncoder.encodeRaw("0x3C1Bd6B420448Cf16A389C8b0115CCB3660bB854", forType: ABIRawType.FixedAddress)
            let filters = [
                EventFilter(type: ERC20Events.Transfer.self, allowedSenders: ["0xdb0040451f373949a4be60dcd7b6b8d6e42658b6"])
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

    func testGivenContractFilter_WhenMatchingMultipleTransferEvents_OnlyMatchingSourceEventsReturned() async {
        do {
            let to = try! ABIEncoder.encode(EthereumAddress("0x3C1Bd6B420448Cf16A389C8b0115CCB3660bB854"))
            let filters = [
                EventFilter(type: ERC20Events.Transfer.self, allowedSenders: ["0xdb0040451f373949a4be60dcd7b6b8d6e42658b6"]),
                EventFilter(type: TransferMatchingSignatureEvent.self, allowedSenders: ["0xdb0040451f373949a4be60dcd7b6b8d6e42658b6"])
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

    func test_GivenDynamicArrayResponse_ThenCallReceivesData() async {
        do {
            let function = GetGuardians(wallet: "0x2A6295C34b4136F2C3c1445c6A0338D784fe0ddd")

            let response = try await function.call(withClient: client!, responseType: GetGuardians.Response.self)
            XCTAssertEqual(response.guardians, ["0x44fe11c90d2bcbc8267a0e56d55235ddc2b96c4f"])
        } catch {
            XCTFail("Expected response but failed \(error).")
        }
    }

    func test_GivenUnimplementedMethod_WhenCallingContract_ThenFailsWithExecutionError() async {
        do {
            let function = InvalidMethodA(param: .zero)
            _ = try await function.call(
                withClient: client!,
                responseType: InvalidMethodA.BoolResponse.self)
            XCTFail("Expected to throw while awaiting, but succeeded")
        } catch {
            XCTAssertEqual(
                error as? EthereumClientError,
                .executionError(
                    .init(code: -32000, message: "execution reverted", data: nil)
                )
            )
        }
    }

    func test_GivenValidTransaction_ThenEstimatesGas() async {
        do {
            let function = TransferToken(wallet: "0xD18dE36e6FB4a5A069f673723Fab71cc00C6CE5F",
                                         token: "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
                                         to: "0x2A6295C34b4136F2C3c1445c6A0338D784fe0ddd",
                                         amount: 1,
                                         data: Data(),
                                         gasPrice: nil,
                                         gasLimit: nil)

            let value = try await client!.eth_estimateGas(try! function.transaction())
            XCTAssert(value != 0)
        } catch {
            XCTFail("Expected value but failed \(error).")
        }
    }
}

struct GetGuardians: ABIFunction {
    static let name = "getGuardians"
    let contract: EthereumAddress = "0x25BD64224b7534f7B9e3E16dd10b6dED1A412b90"
    let from: EthereumAddress? = "0x25BD64224b7534f7B9e3E16dd10b6dED1A412b90"
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
    let contract: EthereumAddress = "0xe4f5384d96cc4e6929b63546082788906250b60b"
    let from: EthereumAddress? = "0xe4f5384d96cc4e6929b63546082788906250b60b"

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
    let contract: EthereumAddress = "0xed0439eacf4c4965ae4613d77a5c2efe10e5f183"
    let from: EthereumAddress? = "0xed0439eacf4c4965ae4613d77a5c2efe10e5f183"
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
    let contract: EthereumAddress = "0xC011A72400E58ecD99Ee497CF89E3775d4bd732F"
    let from: EthereumAddress? = "0xC011A72400E58ecD99Ee497CF89E3775d4bd732F"
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

class EthereumWebSocketClientTests: EthereumClientTests {
    var delegateExpectation: XCTestExpectation?

    override func setUp() {
        super.setUp()
        client = EthereumWebSocketClient(url: URL(string: TestConfig.wssUrl)!, configuration: TestConfig.webSocketConfig)

    }
#if os(Linux)
// On Linux some tests are fail. Need investigation
#else
    func testWebSocketNoAutomaticOpen() {
        self.client = EthereumWebSocketClient(url: URL(string: TestConfig.wssUrl)!, configuration: .init(automaticOpen: false))

        guard let client = client as? EthereumWebSocketClient else {
            XCTFail("Expected client to be EthereumWebSocketClient")
            return
        }

        XCTAssertEqual(client.currentState, WebSocketState.closed)
    }

    func testWebSocketConnect() {
        self.client = EthereumWebSocketClient(url: URL(string: TestConfig.wssUrl)!, configuration: .init(automaticOpen: false))

        guard let client = client as? EthereumWebSocketClient else {
            XCTFail("Expected client to be EthereumWebSocketClient")
            return
        }

        XCTAssertEqual(client.currentState, WebSocketState.closed)

        client.connect()

        XCTAssertEqual(client.currentState, WebSocketState.open)
    }

    func testWebSocketPendingTransactions() async {
        do {
            guard let client = client as? EthereumWebSocketClient else {
                XCTFail("Expected client to be EthereumWebSocketClient")
                return
            }

            var expectation: XCTestExpectation? = self.expectation(description: "Pending Transaction")
            let subscription = try await client.pendingTransactions { _ in
                expectation?.fulfill()
                expectation = nil
            }

            await waitForExpectations(timeout: 5, handler: nil)

            XCTAssertNotEqual(subscription.id, "")
            XCTAssertEqual(subscription.type, .pendingTransactions)
        } catch {
            XCTFail("Expected subscription but failed \(error).")
        }
    }

    func testWebSocketNewBlockHeaders() async {
        do {
            guard let client = client as? EthereumWebSocketClient else {
                XCTFail("Expected client to be EthereumWebSocketClient")
                return
            }

            var expectation: XCTestExpectation? = self.expectation(description: "New Block Headers")
            let subscription = try await client.newBlockHeaders { _ in
                expectation?.fulfill()
                expectation = nil
            }

            // we need a high timeout as new block might take a while
            await waitForExpectations(timeout: 2500, handler: nil)

            XCTAssertNotEqual(subscription.id, "")
            XCTAssertEqual(subscription.type, .newBlockHeaders)
        } catch {
            XCTFail("Expected subscription but failed \(error).")
        }
    }

    func testWebSocketSubscribe() async {
        do {
            guard let client = client as? EthereumWebSocketClient else {
                XCTFail("Expected client to be EthereumWebSocketClient")
                return
            }
            client.delegate = self

            delegateExpectation = expectation(description: "onNewPendingTransaction delegate call")
            var subscription = try await client.subscribe(type: .pendingTransactions)
            await waitForExpectations(timeout: 10)
            _ = try await client.unsubscribe(subscription)

            delegateExpectation = expectation(description: "onNewBlockHeader delegate call")
            subscription = try await client.subscribe(type: .newBlockHeaders)
            await waitForExpectations(timeout: 2500)
            _ = try await client.unsubscribe(subscription)
        } catch {
            XCTFail("Expected subscription but failed \(error).")
        }
    }

    func testWebSocketUnsubscribe() async {
        do {
            guard let client = client as? EthereumWebSocketClient else {
                XCTFail("Expected client to be EthereumWebSocketClient")
                return
            }

            let subscription = try await client.subscribe(type: .newBlockHeaders)
            let result = try await client.unsubscribe(subscription)
            XCTAssertTrue(result)
        } catch {
            XCTFail("Expected subscription but failed \(error).")
        }
    }
#endif
}

extension EthereumWebSocketClientTests: EthereumWebSocketClientDelegate {
    func onNewPendingTransaction(subscription: EthereumSubscription, txHash: String) {
        delegateExpectation?.fulfill()
        delegateExpectation = nil
    }

    func onNewBlockHeader(subscription: EthereumSubscription, header: EthereumHeader) {
        delegateExpectation?.fulfill()
        delegateExpectation = nil
    }
}
