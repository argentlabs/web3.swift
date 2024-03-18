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
        client = EthereumHttpClient(url: URL(string: TestConfig.clientUrl)!, network: TestConfig.network)
        account = try? EthereumAccount(keyStorage: TestEthereumKeyStorage(privateKey: TestConfig.privateKey))
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
            XCTAssertEqual(network, EthereumNetwork.sepolia, "Network incorrect")
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
            let gasPrice = try await client?.eth_gasPrice()
            let tx = EthereumTransaction(from: nil, to: "0x3c1bd6b420448cf16a389c8b0115ccb3660bb854", value: BigUInt(1), data: nil, nonce: 2, gasPrice: gasPrice ?? BigUInt(9000000), gasLimit: BigUInt(30000), chainId: EthereumNetwork.sepolia.intValue)

            let txHash = try await client?.eth_sendRawTransaction(tx, withAccount: account!)
            XCTAssertNotNil(txHash, "No tx hash, ensure key is valid in TestConfig.swift")
        } catch {
            XCTFail("Expected tx but failed \(error).")
        }
    }

    func testEthGetTransactionReceipt() async {
        do {
            let txHash = "0x058af59b2de40c8f745bc8baf403f54b1f7c3a502aff26d36ad3f174649ded1b"
            let receipt = try await client?.eth_getTransactionReceipt(txHash: txHash)
            XCTAssertNotNil(receipt, "Transaction receipt not available")
        } catch {
            XCTFail("Expected receipt but failed \(error).")
        }
    }

    func testEthCall() async {
        do {
            let tx = EthereumTransaction(from: nil, to: "0x3c1bd6b420448cf16a389c8b0115ccb3660bb854", value: BigUInt(1800000), data: nil, nonce: 2, gasPrice: BigUInt(400000), gasLimit: BigUInt(50000), chainId: EthereumNetwork.sepolia.intValue)
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
            let logs = try await client?.eth_getLogs(addresses: nil, orTopics: [["0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925", "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef"], ["0x00000000000000000000000061CA935f8b7847C4a1275814d8D88CDa8d406CC9"]], fromBlock: .Number(4902849), toBlock: .Number(4902849))
            XCTAssertEqual(logs?.count, 1)
            XCTAssertNotNil(logs, "Logs not available")
        } catch {
            XCTFail("Expected logs but failed \(error).")
        }
    }

    func testGivenGenesisBlock_ThenReturnsByNumber() async {
        do {
            let block = try await client?.eth_getBlockByNumber(.Number(0))
            XCTAssertEqual(block?.timestamp.timeIntervalSince1970, 1633267481)
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
            let block = try await client?.eth_getBlockByNumber(.Number(4892410))
            XCTAssertEqual(block?.number, .Number(4892410))
            XCTAssertEqual(block?.timestamp.timeIntervalSince1970, 1702659468)
            XCTAssertEqual(block?.transactions.count, 155)
            XCTAssertEqual(block?.transactions.first, "0x3584af370197e447cd4d9163194dd41910741ded549550c47aace44eea6cf910")
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
            let transaction = try await client?.eth_getTransaction(byHash: "0x058af59b2de40c8f745bc8baf403f54b1f7c3a502aff26d36ad3f174649ded1b")
            XCTAssertEqual(transaction?.from, "0x1E2cD78882b12d3954a049Fd82FFD691565dC0A5")
            XCTAssertEqual(transaction?.to, "0x9b7E335088762aD8061C04D08C37902ABC8ACb87")
            XCTAssertEqual(transaction?.gas, "21000")
            XCTAssertEqual(transaction?.gasPrice, BigUInt(19635664880))
            XCTAssertEqual(transaction?.nonce, 181635)
            XCTAssertEqual(transaction?.value, 542261709133544904)
            XCTAssertEqual(transaction?.blockNumber, EthereumBlock.Number(4892410))
            XCTAssertEqual(transaction?.hash?.web3.hexString, "0x058af59b2de40c8f745bc8baf403f54b1f7c3a502aff26d36ad3f174649ded1b")
        } catch {
            XCTFail("Expected transaction but failed \(error).")
        }
    }

    func testGivenUnexistingTransactionHash_ThenErrorsGetTransactionByHash() async {
        do {
            _ = try await client?.eth_getTransaction(byHash: "0x01234")
            XCTFail("Expected to throw while awaiting, but succeeded")
        } catch {
            XCTAssertNotNil(error as? EthereumClientError)
        }
    }

    func testGivenNoFilters_WhenMatchingSingleTransferEvents_AllEventsReturned() async {
        do {
            let to = try! ABIEncoder.encode(EthereumAddress("0x162142f0508F557C02bEB7C473682D7C91Bcef41"))

            let eventsResult = try await client?.getEvents(addresses: nil,
                                                           topics: [try! ERC20Events.Transfer.signature(), nil, to.hexString, nil],
                                                           fromBlock: .Earliest,
                                                           toBlock: .Latest,
                                                           eventTypes: [ERC20Events.Transfer.self])
            XCTAssertEqual(eventsResult?.logs.count, 4)
            XCTAssertEqual(eventsResult?.events.count, 5)
        } catch {
            XCTFail("Expected events but failed \(error).")
        }
    }

    func testGivenNoFilters_WhenMatchingMultipleTransferEvents_BothEventsReturned() async {
        do {
            let to = try! ABIEncoder.encode(EthereumAddress("0x162142f0508F557C02bEB7C473682D7C91Bcef41"))

            let eventsResult = try await client?.getEvents(addresses: nil,
                                                           topics: [try! ERC20Events.Transfer.signature(), nil, to.hexString, nil],
                                                           fromBlock: .Earliest,
                                                           toBlock: .Latest,
                                                           eventTypes: [ERC20Events.Transfer.self, TransferMatchingSignatureEvent.self])
            XCTAssertEqual(eventsResult?.logs.count, 8)
            XCTAssertEqual(eventsResult?.events.count, 10)
        } catch {
            XCTFail("Expected events but failed \(error).")
        }
    }

    func testGivenContractFilter_WhenMatchingSingleTransferEvents_OnlyMatchingSourceEventReturned() async {
        do {
            let to = try! ABIEncoder.encodeRaw("0x162142f0508F557C02bEB7C473682D7C91Bcef41", forType: ABIRawType.FixedAddress)
            let filters = [
                EventFilter(type: ERC20Events.Transfer.self, allowedSenders: ["0xF31B086459C2cdaC006Feedd9080223964a9cDdB"])
            ]

            let eventsResult = try await client?.getEvents(addresses: nil,
                                                           topics: [try! ERC20Events.Transfer.signature(), nil, to.hexString, nil],
                                                           fromBlock: .Earliest,
                                                           toBlock: .Latest,
                                                           matching: filters)
            XCTAssertEqual(eventsResult?.logs.count, 7)
            XCTAssertEqual(eventsResult?.events.count, 2)
        } catch {
            XCTFail("Expected events but failed \(error).")
        }
    }

    func testGivenContractFilter_WhenMatchingMultipleTransferEvents_OnlyMatchingSourceEventsReturned() async {
        do {
            let to = try! ABIEncoder.encode(EthereumAddress("0x64d0eA4FC60f27E74f1a70Aa6f39D403bBe56793"))
            let filters = [
                EventFilter(type: ERC20Events.Transfer.self, allowedSenders: ["0xF31B086459C2cdaC006Feedd9080223964a9cDdB"]),
                EventFilter(type: TransferMatchingSignatureEvent.self, allowedSenders: ["0xB2a6874c2F71fD4481674BaC945D5407A2318b3E"])
            ]

            let eventsResult = try await client?.getEvents(addresses: nil,
                                                           topics: [try! ERC20Events.Transfer.signature(), nil, to.hexString, nil],
                                                           fromBlock: .Earliest,
                                                           toBlock: .Latest,
                                                           matching: filters)
            XCTAssertEqual(eventsResult?.logs.count, 16)
            XCTAssertEqual(eventsResult?.events.count, 6)
        } catch {
            XCTFail("Expected events but failed \(error).")
        }
    }

    func test_GivenDynamicArrayResponse_ThenCallReceivesData() async {
        do {
            let function = GetDynamicArray()

            let response = try await function.call(withClient: client!, responseType: GetDynamicArray.Response.self)
            XCTAssertEqual(response.addresses, ["0x83f7338d17A85B0a0A8A1AE7Edead4dA571566E0"])
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

    func test_ValueWithLeadingZero_EstimatesGas() async {
        do {
            let tx = EthereumTransaction(from: EthereumAddress("0x162142f0508F557C02bEB7C473682D7C91Bcef41"),
                                         to: EthereumAddress("0x64d0eA4FC60f27E74f1a70Aa6f39D403bBe56793"),
                                         value: BigUInt(5000000000),
                                         data: Data(),
                                         gasPrice: BigUInt(0),
                                         gasLimit: BigUInt(0))
            let value = try await client!.eth_estimateGas(tx)
            XCTAssert(value != 0)
        } catch {
            XCTFail("Expected value but failed \(error).")
        }
    }
}

struct GetDynamicArray: ABIFunction {
    static let name = "getDynamicArray"
    let contract: EthereumAddress = "0x47780bc6093413B52014777F26b2BBb401d85243"
    let from: EthereumAddress? = "0x47780bc6093413B52014777F26b2BBb401d85243"
    let gasPrice: BigUInt? = nil
    let gasLimit: BigUInt? = nil

    struct Response: ABIResponse {
        static var types: [ABIType.Type] = [ABIArray<EthereumAddress>.self]
        let addresses: [EthereumAddress]

        init?(values: [ABIDecoder.DecodedValue]) throws {
            self.addresses = try values[0].decodedArray()

        }
    }

    func encode(to encoder: ABIFunctionEncoder) throws {
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
    let contract: EthereumAddress = "0x47780bc6093413B52014777F26b2BBb401d85243"
    let from: EthereumAddress? = "0x47780bc6093413B52014777F26b2BBb401d85243"
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
        client = EthereumWebSocketClient(url: URL(string: TestConfig.wssUrl)!, configuration: TestConfig.webSocketConfig, network: TestConfig.network)

    }
#if os(Linux)
// On Linux some tests are fail. Need investigation
#else
    func testWebSocketNoAutomaticOpen() {
        self.client = EthereumWebSocketClient(url: URL(string: TestConfig.wssUrl)!, configuration: .init(automaticOpen: false), network: TestConfig.network)

        guard let client = client as? EthereumWebSocketClient else {
            XCTFail("Expected client to be EthereumWebSocketClient")
            return
        }

        XCTAssertEqual(client.currentState, WebSocketState.closed)
    }

    func testWebSocketConnect() {
        self.client = EthereumWebSocketClient(url: URL(string: TestConfig.wssUrl)!, configuration: .init(automaticOpen: false), network: TestConfig.network)

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
            XCTAssertEqual(subscription.type, .newPendingTransactions)
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

    func testWebSocketLogs() async {
        do {
            guard let client = client as? EthereumWebSocketClient else {
                XCTFail("Expected client to be EthereumWebSocketClient")
                return
            }

            var expectation: XCTestExpectation? = self.expectation(description: "Logs")
            let type = EthereumSubscriptionType.logs(nil)
            let subscription = try await client.logs { log in
                print(log)
                expectation?.fulfill()
                expectation = nil
            }

            // we need a high timeout as new block might take a while
            await waitForExpectations(timeout: 2500, handler: nil)

            XCTAssertNotEqual(subscription.id, "")
            XCTAssertEqual(subscription.type, type)
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
            var subscription = try await client.subscribe(type: .newPendingTransactions)
            await waitForExpectations(timeout: 10)
            _ = try await client.unsubscribe(subscription)

            delegateExpectation = expectation(description: "onNewBlockHeader delegate call")
            subscription = try await client.subscribe(type: .newBlockHeaders)
            await waitForExpectations(timeout: 2500)
            _ = try await client.unsubscribe(subscription)

            delegateExpectation = expectation(description: "onLogs delegate call")
            let type = EthereumSubscriptionType.logs(nil)
            subscription = try await client.subscribe(type: type)
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

    func onLog(subscription: EthereumSubscription, log: EthereumLog) {
        delegateExpectation?.fulfill()
        delegateExpectation = nil
    }
}
