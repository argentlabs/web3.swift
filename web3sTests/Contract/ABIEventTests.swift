//
//  ABIEventTests.swift
//  web3swift
//
//  Created by Miguel on 29/07/2020.
//  Copyright © 2020 Argent Labs Limited. All rights reserved.
//

import XCTest
import BigInt
@testable import web3swift

class ABIEventTests: XCTestCase {
    var client: EthereumClient!
    
    override func setUp() {
        self.client = EthereumClient(url: URL(string: TestConfig.clientUrl)!)
    }
    
    func test_givenEventWithData4_ItParsesCorrectly() {
        let expect = expectation(description: "Request")
        
        let encodedAddress = (try? ABIEncoder.encode(EthereumAddress("0x3B6Def16666a23905DD29071d13E7a9db08240E2")).bytes) ?? []
        
        client.getEvents(addresses: nil,
                         topics: [try? EnabledStaticCall.signature(),  String(hexFromBytes: encodedAddress), nil],
                         fromBlock: .Number(8386245),
                         toBlock: .Number(8386245),
                         eventTypes: [EnabledStaticCall.self]) { (error, events, logs) in
                            XCTAssertNil(error)
                            let event = events.first as? EnabledStaticCall
                            XCTAssertEqual(event?.module, EthereumAddress("0x3b6def16666a23905dd29071d13e7a9db08240e2"))
                            XCTAssertEqual(event?.method, Data(hex: "0x20c13b0b")!)
                            
                            let event1 = events.last as? EnabledStaticCall
                            XCTAssertEqual(event1?.module, EthereumAddress("0x3b6def16666a23905dd29071d13e7a9db08240e2"))
                            XCTAssertEqual(event1?.method, Data(hex: "0x1626ba7e")!)
                            expect.fulfill()
        }
        
        waitForExpectations(timeout: 10)
    }
    
    func test_givenEventWithData32_ItParsesCorrectly() {
        let expect = expectation(description: "Request")
        
        client.getEvents(addresses: nil,
                         topics: [try? UpgraderRegistered.signature()],
                         fromBlock: .Number(
                         8110676 ),
                         toBlock: .Number(
                         8110676 ),
                         eventTypes: [UpgraderRegistered.self]) { (error, events, logs) in
                            XCTAssertNil(error)
                            XCTAssertEqual(events.count, 1)
                            let event = events.first as? UpgraderRegistered
                            XCTAssertEqual(event?.upgrader, EthereumAddress("0x17b11d842ae09eddedf5592f8271a7d07f6931e7"))
                            XCTAssertEqual(event?.name, Data(hex: "0x307864323664616666635f307833373731376663310000000000000000000000")!)
                            expect.fulfill()
        }
        
        waitForExpectations(timeout: 10)
    }
}

struct EnabledStaticCall: ABIEvent {
    static let name = "EnabledStaticCall"
    static let types: [ABIType.Type] = [EthereumAddress.self,Data4.self]
    static let typesIndexed = [true,true]
    let log: EthereumLog

    let module: EthereumAddress
    let method: Data

    init?(topics: [ABIType], data: [ABIType], log: EthereumLog) throws {
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
    
    init?(topics: [ABIType], data: [ABIType], log: EthereumLog) throws {
        try UpgraderRegistered.checkParameters(topics, data)
        self.log = log
        
        self.upgrader = try topics[0].decoded()
        self.name = try data[0].decoded()
    }
}
