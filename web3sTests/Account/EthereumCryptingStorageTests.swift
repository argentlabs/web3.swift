//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import XCTest
@testable import web3

final class EthereumCryptingStorageTests: XCTestCase {

    private let addressStub = EthereumAddress("0x675f5810feb3b09528e5cd175061b4eb8de69075")
    private let passwordStub = "PASSWORD"
    private var storageSpy = EthereumKeyStorageSpy()
    private lazy var sut = EthereumCryptingStorage(backingStorage: storageSpy, passwordProvider: { [unowned self] _ in passwordStub })

    func test_givenKeyAndAddressAndOTPPassword_whenStoreCalled_thenStoreDataCalled() async throws {
        // given
        let key = try XCTUnwrap(Data(hex: "2639f727ded571d584643895d43d02a7a190f8249748a2c32200cfc12dde7173"))

        // when
        try await sut.storePrivateKey(key: key, with: addressStub)

        // then
        XCTAssertEqual(storageSpy.storePrivateKeyCallsCount, 1)
        XCTAssertEqual(storageSpy.storePrivateKeyRecordedData.first?.address, addressStub)
        XCTAssertNotEqual(storageSpy.storePrivateKeyRecordedData.first?.key, key)
    }

    func test_givenKeyAndAddressAndOTPPassword_whenLoadCalled_thenLoadDataCalled() async throws {
        // given
        storageSpy.loadPrivateKeyReturnValue = try XCTUnwrap(Data(hex: "7b2261646472657373223a22307836373566353831306665623362303935323865356364313735303631623465623864653639303735222c2276657273696f6e223a332c2263727970746f223a7b2263697068657274657874223a2263616338396633333134653337313730623336313364313734616161366663353239303465386363326335393766663030306564383565376132306535333363222c22636970686572706172616d73223a7b226976223a223266653166356538323535666638356531373565663136636665313664376230227d2c226b6466223a2270626b646632222c226b6466706172616d73223a7b22707266223a22686d61632d736861323536222c2263223a3236323134342c22646b6c656e223a33322c2273616c74223a226437383630316335666634623434333733663761353536663862343735646233227d2c226d6163223a2230333736363237363436346536356333613366373064313661643164383232353230623762633735306238353463343439386132633163356166363563663133222c22636970686572223a226165732d3132382d637472227d7d"))

        // when
        _ = try await sut.loadPrivateKey(for: addressStub)

        // then
        XCTAssertEqual(storageSpy.loadPrivateKeyCallsCount, 1)
        XCTAssertEqual(storageSpy.loadPrivateKeyRecordedData.first, addressStub)
    }

    func test_whenDeleteAllKeysCalled_thenDeleteAllKeysCalled() async throws {
        // when
        try await sut.deleteAllKeys()

        // then
        XCTAssertEqual(storageSpy.deleteAllKeysCallsCount, 1)
    }

    func test_givenAddress_whenDeletePrivateKeyCalled_thenDeletePrivateKeyCalled() async throws {
        // given
        // when
        try await sut.deletePrivateKey(for: addressStub)

        // then
        XCTAssertEqual(storageSpy.deletePrivateKeyCallsCount, 1)
        XCTAssertEqual(storageSpy.deletePrivateKeyRecordedData.first, addressStub)
    }

    func test_givenAddresses_whenFetchAccountsCalled_thenReturnsExpectedAccounts() async throws {
        // given
        let expected = [addressStub]
        storageSpy.fetchAccountsReturnValue = expected

        // when
        let result = try await sut.fetchAccounts()

        // then
        XCTAssertEqual(storageSpy.fetchAccountsCallsCount, 1)
        XCTAssertEqual(result, expected)
    }
}

extension EthereumCryptingStorageTests {

    static func hexString(data: Data?) -> String? {
        guard let data else { return nil }
        return data.map { String(format: "%02x", $0) }.reduce("", +)
    }
}
