//
//  ABIEventTests.swift
//  web3swift
//
//  Created by Miguel on 29/07/2020.
//  Copyright © 2020 Argent Labs Limited. All rights reserved.
//

import XCTest
import BigInt
@testable import web3

class ABIEventTests: XCTestCase {
    var client: EthereumClientProtocol!

    override func setUp() {
        super.setUp()
        self.client = EthereumClient(url: URL(string: TestConfig.clientUrl)!)
    }

    func test_givenEventWithData4_ItParsesCorrectly() async {
        do {
            let encodedAddress = (try? ABIEncoder.encode(EthereumAddress("0x3B6Def16666a23905DD29071d13E7a9db08240E2")).bytes) ?? []

            let eventsResult = try await client.getEvents(addresses: nil,
                                                          topics: [try? EnabledStaticCall.signature(),  String(hexFromBytes: encodedAddress), nil],
                                                          fromBlock: .Number(8386245),
                                                          toBlock: .Number(8386245),
                                                          eventTypes: [EnabledStaticCall.self])

            let eventFirst = eventsResult.events.first as? EnabledStaticCall
            XCTAssertEqual(eventFirst?.module, EthereumAddress("0x3b6def16666a23905dd29071d13e7a9db08240e2"))
            XCTAssertEqual(eventFirst?.method, Data(hex: "0x20c13b0b")!)

            let eventLast = eventsResult.events.last as? EnabledStaticCall
            XCTAssertEqual(eventLast?.module, EthereumAddress("0x3b6def16666a23905dd29071d13e7a9db08240e2"))
            XCTAssertEqual(eventLast?.method, Data(hex: "0x1626ba7e")!)
        } catch {
            XCTFail("Expected events but failed \(error).")
        }
    }

    func test_givenEventWithData32_ItParsesCorrectly() async {
        do {
            let eventsResult = try await client.getEvents(addresses: nil,
                                                          topics: [try? UpgraderRegistered.signature()],
                                                          fromBlock: .Number(
                                                            8110676 ),
                                                          toBlock: .Number(
                                                            8110676 ),
                                                          eventTypes: [UpgraderRegistered.self])

            XCTAssertEqual(eventsResult.events.count, 1)
            let event = eventsResult.events.first as? UpgraderRegistered
            XCTAssertEqual(event?.upgrader, EthereumAddress("0x17b11d842ae09eddedf5592f8271a7d07f6931e7"))
            XCTAssertEqual(event?.name, Data(hex: "0x307864323664616666635f307833373731376663310000000000000000000000")!)
        } catch {
            XCTFail("Expected events but failed \(error).")
        }
    }
}

class ABIEventWebSocketTests: ABIEventTests {
    override func setUp() {
        super.setUp()
        self.client = EthereumWebSocketClient(url: TestConfig.wssUrl, configuration: TestConfig.webSocketConfig)
    }
}

struct EnabledStaticCall: ABIEvent {
    static let name = "EnabledStaticCall"
    static let types: [ABIType.Type] = [EthereumAddress.self,Data4.self]
    static let typesIndexed = [true,true]
    let log: EthereumLog

    let module: EthereumAddress
    let method: Data

    init?(topics: [ABIDecoder.DecodedValue], data: [ABIDecoder.DecodedValue], log: EthereumLog) throws {
        try EnabledStaticCall.checkParameters(topics, data)
        self.log = log

        self.module = try topics[0].decoded()
        self.method = try topics[1].decoded()

    }
}

struct UpgraderRegistered: ABIEvent {
    static let name = "UpgraderRegistered"
    static let types: [ABIType.Type] = [EthereumAddress.self,Data32.self]
    static let typesIndexed = [true,false]
    let log: EthereumLog

    let upgrader: EthereumAddress
    let name: Data

    init?(topics: [ABIDecoder.DecodedValue], data: [ABIDecoder.DecodedValue], log: EthereumLog) throws {
        try UpgraderRegistered.checkParameters(topics, data)
        self.log = log

        self.upgrader = try topics[0].decoded()
        self.name = try data[0].decoded()
    }
}

