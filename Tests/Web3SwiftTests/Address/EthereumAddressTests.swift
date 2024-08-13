//
//  web3.swift
//  Copyright © 2023 Argent Labs Limited. All rights reserved.
//

import XCTest
@testable import web3

class EthereumAddressTests: XCTestCase {
    private var values: Set<EthereumAddress>!
    private let addr1 = EthereumAddress("0x162142f0508F557C02bEB7C473682D7C91Bcef41")
    private let addr1Padded = EthereumAddress("0x0162142f0508F557C02bEB7C473682D7C91Bcef41")
    private let addr2 = EthereumAddress("0x162142f0508F557C02bEB7C473682D7C91Bcef42")

    func testGivenAddress_WhenComparingWithSameAddressString_AddressIsEqual() {
        XCTAssertEqual(addr1, addr1)
    }

    func testGivenAddress_WhenHashingWithSameAddressString_AddressIsEqual() {
        values = [addr1]
        XCTAssertTrue(values.contains(addr1))
    }

    func testGivenAddress_WhenComparingWithDifferentAddressString_AddressNotEqual() {
        XCTAssertNotEqual(addr1, addr2)
    }

    func testGivenAddress_WhenComparingWith0PaddedAddress_AddressIsEqual() {
        XCTAssertEqual(addr1, addr1Padded)
    }

    func testGivenAddress_WhenHashingWith0PaddedAddress_AddressIsEqual() {
        values = [addr1]
        XCTAssertTrue(values.contains(addr1Padded))
    }

    func testGiven0PaddedAddress_WhenHashingWithNotPaddedAddress_AddressIsEqual() {
        values = [addr1Padded]
        XCTAssertTrue(values.contains(addr1))
    }

    func testGivenAddress_WhenHashing_EqualToSameAddressHash() {
        XCTAssertEqual(addr1.hashValue, addr1.hashValue)
    }

    func testGivenAddress_WhenHashing_EqualToPaddedAddressHash() {
        XCTAssertEqual(addr1.hashValue, addr1Padded.hashValue)
    }
}
