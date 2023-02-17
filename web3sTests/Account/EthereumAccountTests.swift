//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import XCTest
@testable import web3

class EthereumAccountTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }
    
    func testLoadAccountAndAddress() {
        let account = try! EthereumAccount(keyStorage: TestEthereumKeyStorage(privateKey: TestConfig.privateKey))
        XCTAssertEqual(account.address, EthereumAddress(TestConfig.publicKey), "Failed to load private key. Ensure key is valid in TestConfig.swift")
    }

    func testLoadAccountAndAddressMultiple() {
        let storage = TestEthereumMultipleKeyStorage(privateKey: TestConfig.privateKey)
        let account = try! EthereumAccount(addressString: TestConfig.publicKey, keyStorage: storage)
        XCTAssertEqual(account.address, EthereumAddress(TestConfig.publicKey), "Failed to load private key. Ensure key is valid in TestConfig.swift")
    }

    func testCreateAccount() {
        let storage = EthereumKeyLocalStorage()
        let account = try? EthereumAccount.create(replacing: storage, keystorePassword: "PASSWORD")
        XCTAssertNotNil(account, "Failed to create account. Ensure key is valid in TestConfig.swift")
    }
    
    func testCreateAccountMultiple() {
        let storage = EthereumKeyLocalStorage()
        let account = try? EthereumAccount.create(addingTo: storage, keystorePassword: "PASSWORD")
        XCTAssertNotNil(account, "Failed to create account. Ensure key is valid in TestConfig.swift")
    }

    func testImportAccount() {
        let storage = EthereumKeyLocalStorage()
        let account = try! EthereumAccount.importAccount(replacing: storage, privateKey: "0x2639f727ded571d584643895d43d02a7a190f8249748a2c32200cfc12dde7173", keystorePassword: "PASSWORD")

        XCTAssertEqual(account.address, "0x675f5810feb3b09528e5cd175061b4eb8de69075")
    }
    
    func testImportAccountMultiple() {
        let storage = EthereumKeyLocalStorage()
        let account = try! EthereumAccount.importAccount(addingTo: storage, privateKey: "0x2639f727ded571d584643895d43d02a7a190f8249748a2c32200cfc12dde7173", keystorePassword: "PASSWORD")

        XCTAssertEqual(account.address, "0x675f5810feb3b09528e5cd175061b4eb8de69075")
    }
    
    func testFetchAccounts() {
        let storage = EthereumKeyLocalStorage()
        let account = try! EthereumAccount.importAccount(addingTo: storage, privateKey: "0x2639f727ded571d584643895d43d02a7a190f8249748a2c32200cfc12dde7173", keystorePassword: "PASSWORD")
        let accounts = try! storage.fetchAccounts()
        XCTAssertTrue(accounts.contains(account.address))
    }
    
    func testDeleteAccount() {
        let storage = EthereumKeyLocalStorage()
        let account = try! EthereumAccount.importAccount(addingTo: storage, privateKey: "0x2639f727ded571d584643895d43d02a7a190f8249748a2c32200cfc12dde7173", keystorePassword: "PASSWORD")
        let ethereumAddress = EthereumAddress("0x675f5810feb3b09528e5cd175061b4eb8de69075")
        try! storage.deletePrivateKey(for: ethereumAddress)
        let accounts = try! storage.fetchAccounts()
        XCTAssertTrue(!accounts.contains(account.address))
    }
    
    func testSignMessage() {
        let account = try! EthereumAccount(keyStorage: TestEthereumKeyStorage(privateKey: "0x2639f727ded571d584643895d43d02a7a190f8249748a2c32200cfc12dde7173"))
        let signature = try! account.sign(message: "Hello message!")

        let expectedSignature = "7f89b86ee3ca79d32324b9c2ede02385b5a32ecd7c0caf5d7ceb0b34cf7c90697627d1cb3435c16bb72866273eb14bd9f387d74591382add29d4e39b8c11167300"

        XCTAssertEqual(signature.web3.hexString.web3.noHexPrefix, expectedSignature)
    }
    
    func testSignData() {
        let account = try! EthereumAccount(keyStorage: TestEthereumKeyStorage(privateKey: "0x2639f727ded571d584643895d43d02a7a190f8249748a2c32200cfc12dde7173"))
        let signature = try! account.sign(data: "Hello message!".data(using: .utf8)!)

        let expectedSignature = "7f89b86ee3ca79d32324b9c2ede02385b5a32ecd7c0caf5d7ceb0b34cf7c90697627d1cb3435c16bb72866273eb14bd9f387d74591382add29d4e39b8c11167300"

        XCTAssertEqual(signature.web3.hexString.web3.noHexPrefix, expectedSignature)
    }
    
    func testSignHash() {
        let account = try! EthereumAccount(keyStorage: TestEthereumKeyStorage(privateKey: "774681694ad86635346b6e9b92fa8aa4806265336dc6766623029a6264a162c1"))
        let signature = try! account.sign(hash: "0x9dd2c369a187b4e6b9c402f030e50743e619301ea62aa4c0737d4ef7e10a3d49")

        let expectedSignature = "16f89ddb9bf9ec08ff696bc766e675da7cfcb4f0b10bc8ce7c1a87a414a65a4f19c05c207e1b59f2e1cd18053cb8406fb7c6d22cec5e348d6217febbff8fc19801"

        XCTAssertEqual(signature.web3.hexString.web3.noHexPrefix, expectedSignature)
    }
    
    func testSignHex() {
        let account = try! EthereumAccount(keyStorage: TestEthereumKeyStorage(privateKey: "2639f727ded571d584643895d43d02a7a190f8249748a2c32200cfc12dde7173"))
        let signature = try! account.sign(hex: "0xe5808504a817c80082520894f59fc5a335e75060ff18beed2d6c8fbbbdab0dc2843b9aca0080")

        let expectedSignature = "8152ada8bece83905602d6b9a8a0f137dace41cd6a2da9d3fb26baa9fb79e2080e871937b634213a0e4cd7dee00c119567fa53096532e88ddf0fb183097bb4d701"

        XCTAssertEqual(signature.web3.hexString.web3.noHexPrefix, expectedSignature)
    }

    func testSignTxHash() {
        let account = try! EthereumAccount(keyStorage: TestEthereumKeyStorage(privateKey: "0x4646464646464646464646464646464646464646464646464646464646464646"))
        let signature = try! account.sign(hash: "0xdaf5a779ae972f972197303d7b574746c7ef83eadac0f2791ad23db92e4c8e53")
        let expectedSignature = "28ef61340bd939bc2195fe537567866003e1a15d3c71ff63e1590620aa63627667cbe9d8997f761aecb703304b3800ccf555c9f3dc64214b297fb1966a3b6d8300"

        XCTAssertEqual(signature.web3.hexString.web3.noHexPrefix, expectedSignature)
    }
    
    func test_toChecksumAddress() {
        let add1: EthereumAddress = "0x12ae66cdc592e10b60f9097a7b0d3c59fce29876"
        let add2: EthereumAddress = "0x90f8bf6a479f320ead074411a4b0e7944ea8c9c1"
        XCTAssertEqual(add1.toChecksumAddress(), "0x12AE66CDc592e10B60f9097a7b0D3C59fce29876")
        XCTAssertEqual(add2.toChecksumAddress(), "0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1")
    }
}
