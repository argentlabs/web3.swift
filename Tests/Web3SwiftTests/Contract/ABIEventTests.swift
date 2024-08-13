//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import BigInt
import XCTest
@testable import web3

class ABIEventTests: XCTestCase {
    var client: EthereumClientProtocol!

    override func setUp() {
        super.setUp()
        client = EthereumHttpClient(url: URL(string: TestConfig.clientUrl)!, network: TestConfig.network)
    }
    
    func test_givenEventWithData4_ItParsesCorrectly() async {
        do {
            let encodedAddress = (try? ABIEncoder.encode(EthereumAddress("0x787411394Ccb38483a6F303FDee075f3EA67D65F")).bytes) ?? []

            let eventsResult = try await client.getEvents(addresses: nil,
                                                          topics: [try? AddressAndData4Event.signature(), String(hexFromBytes: encodedAddress), nil],
                                                          fromBlock: .Number(4916814 ),
                                                          toBlock: .Number(4916814 ),
                                                          eventTypes: [AddressAndData4Event.self])

            let eventFirst = eventsResult.events.first as? AddressAndData4Event
            XCTAssertEqual(eventFirst?.address, EthereumAddress("0x787411394Ccb38483a6F303FDee075f3EA67D65F"))
            XCTAssertEqual(eventFirst?.data, Data(hex: "0x05f50234")!)

            let eventLast = eventsResult.events.last as? AddressAndData4Event
            XCTAssertEqual(eventLast?.address, EthereumAddress("0x787411394Ccb38483a6F303FDee075f3EA67D65F"))
            XCTAssertEqual(eventLast?.data, Data(hex: "0xdeadbeef")!)
        } catch {
            XCTFail("Expected events but failed \(error).")
        }
    }

    func test_givenEventWithData32_ItParsesCorrectly() async {
        do {
            let eventsResult = try await client.getEvents(addresses: nil,
                                                          topics: [try? AddressAndData32Event.signature()],
                                                          fromBlock: .Number(
                                                            4916812 ),
                                                          toBlock: .Number(
                                                            4916812 ),
                                                          eventTypes: [AddressAndData32Event.self])

            XCTAssertEqual(eventsResult.events.count, 1)
            let event = eventsResult.events.first as? AddressAndData32Event
            XCTAssertEqual(event?.address, EthereumAddress("0x787411394Ccb38483a6F303FDee075f3EA67D65F"))
            XCTAssertEqual(event?.data, Data(hex: "05f5023424311e0f21827eba3fbe0dc4c3810a9d49fae3a16bf2b9d12c33d576")!)
        } catch {
            XCTFail("Expected events but failed \(error).")
        }
    }
}

class ABIEventWebSocketTests: ABIEventTests {
    override func setUp() {
        super.setUp()
        client = EthereumWebSocketClient(url: URL(string: TestConfig.wssUrl)!, configuration: TestConfig.webSocketConfig, network: TestConfig.network)
    }
}

struct AddressAndData4Event: ABIEvent {
    static let name = "AddressAndData4Event"
    static let types: [ABIType.Type] = [EthereumAddress.self, Data4.self]
    static let typesIndexed = [true, true]
    let log: EthereumLog

    let address: EthereumAddress
    let data: Data

    init?(topics: [ABIDecoder.DecodedValue], data: [ABIDecoder.DecodedValue], log: EthereumLog) throws {
        try AddressAndData4Event.checkParameters(topics, data)
        self.log = log

        self.address = try topics[0].decoded()
        self.data = try topics[1].decoded()

    }
}

struct AddressAndData32Event: ABIEvent {
    static let name = "AddressAndData32Event"
    static let types: [ABIType.Type] = [EthereumAddress.self, Data32.self]
    static let typesIndexed = [true, false]
    let log: EthereumLog

    let address: EthereumAddress
    let data: Data

    init?(topics: [ABIDecoder.DecodedValue], data: [ABIDecoder.DecodedValue], log: EthereumLog) throws {
        try AddressAndData32Event.checkParameters(topics, data)
        self.log = log

        self.address = try topics[0].decoded()
        self.data = try data[0].decoded()
    }
}
