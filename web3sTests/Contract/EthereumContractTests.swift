//
//  EthereumContractTests.swift
//  web3sTests
//
//  Created by Julien Niset on 21/02/2018.
//  Copyright © 2018 Argent Labs. All rights reserved.
//

import XCTest
@testable import web3swift

class EthereumContractTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testContractParsing() {
        let abi = """
        [{"constant":true,"inputs":[{"name":"_node","type":"bytes32"}],"name":"resolver","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"_node","type":"bytes32"}],"name":"owner","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_node","type":"bytes32"},{"name":"_label","type":"bytes32"},{"name":"_owner","type":"address"}],"name":"setSubnodeOwner","outputs":[],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_node","type":"bytes32"},{"name":"_ttl","type":"uint64"}],"name":"setTTL","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"_node","type":"bytes32"}],"name":"ttl","outputs":[{"name":"","type":"uint64"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_node","type":"bytes32"},{"name":"_resolver","type":"address"}],"name":"setResolver","outputs":[],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_node","type":"bytes32"},{"name":"_owner","type":"address"}],"name":"setOwner","outputs":[],"payable":false,"type":"function"},{"inputs":[],"payable":false,"type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"name":"_node","type":"bytes32"},{"indexed":true,"name":"_label","type":"bytes32"},{"indexed":false,"name":"_owner","type":"address"}],"name":"NewOwner","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"_node","type":"bytes32"},{"indexed":false,"name":"_owner","type":"address"}],"name":"Transfer","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"_node","type":"bytes32"},{"indexed":false,"name":"_resolver","type":"address"}],"name":"NewResolver","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"_node","type":"bytes32"},{"indexed":false,"name":"_ttl","type":"uint64"}],"name":"NewTTL","type":"event"}]
        """
        
        let contract = EthereumContract(json: abi, address: "0x0")
        
        XCTAssertEqual(contract!.functions.count, 7)
        XCTAssertEqual(contract!.events.count, 4)
    }
    
}
