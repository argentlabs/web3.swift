//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import BigInt
import XCTest
@testable import web3

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

let tokenOwner = EthereumAddress("0x162142f0508F557C02bEB7C473682D7C91Bcef41")
let previousOwner = EthereumAddress("0x64d0ea4fc60f27e74f1a70aa6f39d403bbe56793")
let nonOwner = EthereumAddress("0x64d0eA4FC60f27E74f1a70Aa6f39D403bBe56792")
let nftImageURL = URL(string: "https://camo.githubusercontent.com/337987fd840686af3ccd336ecb6f76c8d9682539086a5b77f565cb71e6ad167c/68747470733a2f2f7261772e6769746875622e636f6d2f617267656e746c6162732f776562332e73776966742f6d61737465722f7765623373776966742e706e67")!
let nftURL = URL(string: "https://raw.githubusercontent.com/argentlabs/web3.swift/tech/migrate-goerli/web3sTests/Resources/ERC721Metadata.json")!

class ERC721Tests: XCTestCase {
    var client: EthereumClientProtocol!
    var erc721: ERC721!
    let address = EthereumAddress(TestConfig.erc721Contract)

    override func setUp() {
        super.setUp()
        client = EthereumHttpClient(url: URL(string: TestConfig.clientUrl)!, network: TestConfig.network)
        erc721 = ERC721(client: client)
    }

    func test_GivenAccountWithNFT_ThenBalanceCorrect() async {
        do {
            let balance = try await erc721.balanceOf(contract: address, address: tokenOwner)
            XCTAssertEqual(balance, BigUInt(3))
        } catch {
            XCTFail("Expected balance but failed \(error).")
        }
    }

    func test_GivenAccountWithNOBalance_ThenBalanceCorrect() async {
        do {
            let balance = try await erc721.balanceOf(contract: address, address: nonOwner)
            XCTAssertEqual(balance, BigUInt(0))
        } catch {
            XCTFail("Expected balance but failed \(error).")
        }
    }

    func test_GivenAccountWithNFT_ThenOwnerOfNFTIsAccount() async {
        do {
            let balance = try await erc721.ownerOf(contract: address, tokenId: 1)
            XCTAssertEqual(balance, tokenOwner)
        } catch {
            XCTFail("Expected OwnerOf but failed \(error).")
        }
    }

    func test_GivenAccountWithNFT_ThenOwnerOfAnotherNFTIsNotAccount() async {
        do {
            let balance = try await erc721.ownerOf(contract: address, tokenId: 3)
            XCTAssertNotEqual(balance, tokenOwner)
        } catch {
            XCTFail("Expected OwnerOf but failed \(error).")
        }
    }

    func test_GivenAddressWithTransfer_FindsInTransferEvent() async {
        do {
            let events = try await erc721.transferEventsTo(recipient: tokenOwner,
                                                           fromBlock: .Number(
                                                            4916900  ),
                                                           toBlock: .Number(
                                                            4916900 ))
            XCTAssertEqual(events.first?.from, previousOwner)
            XCTAssertEqual(events.first?.to, tokenOwner)
            XCTAssertEqual(events.first?.tokenId, 0)
        } catch {
            XCTFail("Expected Events but failed \(error).")
        }
    }

    func test_GivenAddressWithTransfer_FindsOutTransferEvent() async {
        do {
            let events = try await erc721.transferEventsFrom(sender: previousOwner,
                                                             fromBlock: .Number(
                                                                4916900),
                                                             toBlock: .Number(
                                                                4916900))
            XCTAssertEqual(events.first?.to, tokenOwner)
            XCTAssertEqual(events.first?.from, previousOwner)
            XCTAssertEqual(events.first?.tokenId, 0)
        } catch {
            XCTFail("Expected Events but failed \(error).")
        }
    }
}

class ERC721MetadataTests: XCTestCase {
    var client: EthereumClientProtocol!
    var erc721: ERC721Metadata!
    let address = EthereumAddress(TestConfig.erc721Contract)
    let nftDetails = ERC721Metadata.Token(
        title: "Test token metadata",
        type: "object",
        properties: ERC721Metadata.Token.Properties(
            name: ERC721Metadata.Token.Property(description: "Unnamed"),
            description: ERC721Metadata.Token.Property(description: "Test ERC721 token"),
            image: ERC721Metadata.Token.Property(description: nftImageURL)
        )
    )

    override func setUp() {
        super.setUp()
        client = EthereumHttpClient(url: URL(string: TestConfig.clientUrl)!, network: TestConfig.network)
        erc721 = ERC721Metadata(client: client, metadataSession: URLSession.shared)
    }

    func test_InterfaceIDMatch() {
        XCTAssertEqual(ERC721MetadataFunctions.interfaceId.web3.hexString, "0x5b5e139f")
    }

    func test_ReturnsName() async {
        do {
            let name = try await erc721.name(contract: address)
            XCTAssertEqual(name, "web3.swift token")
        } catch {
            XCTFail("Expected name but failed \(error).")
        }
    }

    func test_ReturnsSymbol() async {
        do {
            let symbol = try await erc721.symbol(contract: address)
            XCTAssertEqual(symbol, "WEB3T")
        } catch {
            XCTFail("Expected symbol but failed \(error).")
        }
    }

    func test_ReturnsMetatadaURI() async {
        do {
            let url = try await erc721.tokenURI(contract: address, tokenID: 23)
            XCTAssertEqual(url, nftURL)
        } catch {
            XCTFail("Expected tokenURI but failed \(error).")
        }
    }

    func test_ReturnsMetatada() async {
        do {
            let metadata = try await erc721.tokenMetadata(contract: address, tokenID: 23)
            XCTAssertEqual(metadata, nftDetails)
        } catch {
            XCTFail("Expected tokenMetadata but failed \(error).")
        }
    }
}

class ERC721EnumerableTests: XCTestCase {
    var client: EthereumClientProtocol!
    var erc721: ERC721Enumerable!
    let address = EthereumAddress(TestConfig.erc721Contract)

    override func setUp() {
        super.setUp()
        client = EthereumHttpClient(url: URL(string: TestConfig.clientUrl)!, network: TestConfig.network)
        erc721 = ERC721Enumerable(client: client)
    }

    func test_InterfaceIDMatch() {
        XCTAssertEqual(ERC721EnumerableFunctions.interfaceId.web3.hexString, "0x780e9d63")
    }

    func test_returnsTotalSupply() async {
        do {
            let supply = try await erc721.totalSupply(contract: address)
            XCTAssertGreaterThan(supply, 1)
        } catch {
            XCTFail("Expected totalSupply but failed \(error).")
        }
    }

    func test_returnsTokenByIndex() async {
        do {
            let index = try await erc721.tokenByIndex(contract: address, index: 2)
            XCTAssertEqual(index, 2)
        } catch {
            XCTFail("Expected tokenByIndex but failed \(error).")
        }
    }

    func test_GivenAddressWithNFT_returnsTokenOfOwnerByIndex() async {
        do {
            let tokenID = try await erc721.tokenOfOwnerByIndex(contract: address, owner: tokenOwner, index: 2)
            XCTAssertEqual(tokenID, 2)
        } catch {
            XCTFail("Expected tokenByIndex but failed \(error).")
        }
    }

    func test_GivenAddressWithNoNFT_returnsIdZero() async {
        do {
            let tokenID = try await erc721.tokenOfOwnerByIndex(contract: address, owner: nonOwner, index: 0)
            XCTAssertEqual(tokenID, 0)
        } catch {
            XCTFail("Expected tokenByIndex but failed \(error).")
        }
    }
}

class ERC721WebSocketTests: ERC721Tests {
    override func setUp() {
        super.setUp()
        client = EthereumWebSocketClient(url: URL(string: TestConfig.wssUrl)!, configuration: TestConfig.webSocketConfig, network: TestConfig.network)
    }
}

class ERC721MetadataWebSocketTests: ERC721MetadataTests {
    override func setUp() {
        super.setUp()
        client = EthereumWebSocketClient(url: URL(string: TestConfig.wssUrl)!, configuration: TestConfig.webSocketConfig, network: TestConfig.network)
    }
}

class ERC721EnumerableWebSocketTests: ERC721EnumerableTests {
    override func setUp() {
        super.setUp()
        client = EthereumWebSocketClient(url: URL(string: TestConfig.wssUrl)!, configuration: TestConfig.webSocketConfig, network: TestConfig.network)
    }
}
