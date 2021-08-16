//
//  ERC721Tests.swift
//  web3swift
//
//  Created by Miguel on 09/05/2019.
//  Copyright © 2019 Argent Labs Limited. All rights reserved.
//

import XCTest
import BigInt
@testable import web3

let tokenOwner = EthereumAddress("0x69F84b91E7107206E841748C2B52294A1176D45e")
let previousOwner = EthereumAddress("0x64d0ea4fc60f27e74f1a70aa6f39d403bbe56793")
let nonOwner = EthereumAddress("0x64d0eA4FC60f27E74f1a70Aa6f39D403bBe56792")
let nftImageURL = URL(string: "https://ipfs.io/ipfs/QmUDJMmiJEsueLbr6jxh7vhSSFAvjfYTLC64hgkQm1vH2C/graph.svg")!
let nftURL = URL(string: "https://ipfs.io/ipfs/QmUtKP7LnZnL2pWw2ERvNDndP9v5EPoJH7g566XNdgoRfE")!

class ERC721AsyncTests: XCTestCase {
    var client: EthereumClient!
    var erc721: ERC721!
    let address = EthereumAddress(TestConfig.erc721Contract)
    
    
    override func setUp() {
        super.setUp()
        self.client = EthereumClient(url: URL(string: TestConfig.clientUrl)!)
        self.erc721 = ERC721(client: client)
    }
    
    func test_GivenAccountWithNFT_ThenBalanceCorrect() async throws {
        let balance = try await erc721.balanceOf(contract: address, address: tokenOwner)
        XCTAssertEqual(balance, BigUInt(3))
    }
    
    func test_GivenAccountWithNOBalance_ThenBalanceCorrect() async throws {
        let balance = try await erc721.balanceOf(contract: address, address: nonOwner)
        XCTAssertEqual(balance, BigUInt(0))
    }
    
    func test_GivenAccountWithNFT_ThenOwnerOfNFTIsAccount() async throws {
        let balance = try await erc721.ownerOf(contract: address, tokenId: 23)
        XCTAssertEqual(balance, tokenOwner)
    }
    
    func test_GivenAccountWithNFT_ThenOwnerOfAnotherNFTIsNotAccount() async throws {
        let balance = try await erc721.ownerOf(contract: address, tokenId: 22)
        XCTAssertNotEqual(balance, tokenOwner)
    }
    
    func test_GivenAddressWithTransfer_FindsInTransferEvent() async throws {
        let events = try await erc721.transferEventsTo(recipient: tokenOwner,
                                fromBlock: .number(6948276),
                                toBlock: .number(6948276))

        XCTAssertEqual(events.first?.from, previousOwner)
        XCTAssertEqual(events.first?.to, tokenOwner)
        XCTAssertEqual(events.first?.tokenId, 23)
    }
    
    func test_GivenAddressWithTransfer_FindsOutTransferEvent() async throws {
        let events = try await erc721.transferEventsFrom(sender: previousOwner,
                                fromBlock: .number(6948276),
                                toBlock: .number(6948276))
        XCTAssertEqual(events.first?.to, tokenOwner)
        XCTAssertEqual(events.first?.from, previousOwner)
        XCTAssertEqual(events.first?.tokenId, 23)
    }
}

class ERC721MetadataAsyncTests: XCTestCase {
    var client: EthereumClient!
    var erc721: ERC721Metadata!
    let address = EthereumAddress(TestConfig.erc721Contract)
    let nftDetails = ERC721Metadata.Token(title: "Asset Metadata",
                                          type: "object",
                                          properties: ERC721Metadata.Token.Properties(name: ERC721Metadata.Token.Property(description: "Random Graph Token"),
                                                                                      description: ERC721Metadata.Token.Property(description: "NFT to represent Random Graph"),
                                                                                      image:  ERC721Metadata.Token.Property(description: nftImageURL)))
    
    override func setUp() {
        super.setUp()
        self.client = EthereumClient(url: URL(string: TestConfig.clientUrl)!)
        self.erc721 = ERC721Metadata(client: client, metadataSession: URLSession.shared)
    }
    
    
    func test_InterfaceIDMatch() {
        XCTAssertEqual(ERC721MetadataFunctions.interfaceId.web3.hexString, "0x5b5e139f")
    }
    
    func test_ReturnsName() async throws {
        let name = try await erc721.name(contract: address)
        XCTAssertEqual(name, "Graph Art Token")
    }
    
    func test_ReturnsSymbol() async throws {
        let symbol = try await erc721.symbol(contract: address)
        XCTAssertEqual(symbol, "GAT")
    }
    
    func test_ReturnsMetatadaURI() async throws {
        let url = try await erc721.tokenURI(contract: address, tokenID: 23)
        XCTAssertEqual(url, nftURL)
    }
    
    func test_ReturnsMetatada() async throws {
        let metadata = try await erc721.tokenMetadata(contract: address, tokenID: 23)
        XCTAssertEqual(metadata, self.nftDetails)
    }
}

class ERC721EnumerableAsyncTests: XCTestCase {
    var client: EthereumClient!
    var erc721: ERC721Enumerable!
    let address = EthereumAddress(TestConfig.erc721Contract)
    
    override func setUp() {
        super.setUp()
        self.client = EthereumClient(url: URL(string: TestConfig.clientUrl)!)
        self.erc721 = ERC721Enumerable(client: client)
    }
    
    func test_InterfaceIDMatch() {
        XCTAssertEqual(ERC721EnumerableFunctions.interfaceId.web3.hexString, "0x780e9d63")
    }
    
    func test_returnsTotalSupply() async throws {
        let supply = try await erc721.totalSupply(contract: address)
        XCTAssertGreaterThan(supply, 22)
    }
    
    func test_returnsTokenByIndex() async throws {
        let index = try await erc721.tokenByIndex(contract: address, index: 22)
        XCTAssertEqual(index, 23)
    }
    
    func test_GivenAddressWithNFT_returnsTokenOfOwnerByIndex() async throws {
        let tokenID = try await erc721.tokenOfOwnerByIndex(contract: address, owner: tokenOwner, index: 2)
        XCTAssertEqual(tokenID, 23)
    }
    
    func test_GivenAddressWithNoNFT_returnsIdZero() async throws {
        let tokenID = try await erc721.tokenOfOwnerByIndex(contract: address, owner: nonOwner, index: 0)
        XCTAssertEqual(tokenID, 0)
    }
}
