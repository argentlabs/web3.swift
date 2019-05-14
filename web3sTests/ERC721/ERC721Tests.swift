//
//  ERC721Tests.swift
//  web3swift
//
//  Created by Miguel on 09/05/2019.
//  Copyright © 2019 Argent Labs Limited. All rights reserved.
//

import XCTest
import BigInt
@testable import web3swift

let tokenOwner = EthereumAddress("0x64d0eA4FC60f27E74f1a70Aa6f39D403bBe56793")
let nonOwner = EthereumAddress("0x64d0eA4FC60f27E74f1a70Aa6f39D403bBe56792")
let nftImageURL = URL(string: "https://ipfs.io/ipfs/QmUDJMmiJEsueLbr6jxh7vhSSFAvjfYTLC64hgkQm1vH2C/graph.svg")!
let nftURL = URL(string: "https://ipfs.io/ipfs/QmUtKP7LnZnL2pWw2ERvNDndP9v5EPoJH7g566XNdgoRfE")!

class ERC721Tests: XCTestCase {
    var client: EthereumClient!
    var erc721: ERC721!
    let address = EthereumAddress(TestConfig.erc721Contract)
    
    
    override func setUp() {
        super.setUp()
        self.client = EthereumClient(url: URL(string: TestConfig.clientUrl)!)
        self.erc721 = ERC721(client: client)
    }
    
    func test_GivenAccountWithNFT_ThenBalanceCorrect() {
        let expect = expectation(description: "BalanceOf")
        erc721.balanceOf(contract: address, address: tokenOwner) { (error, balance) in
            XCTAssertNil(error)
            XCTAssertEqual(balance, BigUInt(1))
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 10)
    }
    
    func test_GivenAccountWithNOBalance_ThenBalanceCorrect() {
        let expect = expectation(description: "BalanceOf")
        erc721.balanceOf(contract: address, address: nonOwner) { (error, balance) in
            XCTAssertNil(error)
            XCTAssertEqual(balance, BigUInt(0))
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 10)
    }
    
    func test_GivenAccountWithNFT_ThenOwnerOfNFTIsAccount() {
        let expect = expectation(description: "OwnerOf")
        erc721.ownerOf(contract: address, tokenId: 23) { (error, balance) in
            XCTAssertNil(error)
            XCTAssertEqual(balance, tokenOwner)
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 10)
    }
    
    func test_GivenAccountWithNFT_ThenOwnerOfAnotherNFTIsNotAccount() {
        let expect = expectation(description: "OwnerOf")
        erc721.ownerOf(contract: address, tokenId: 22) { (error, balance) in
            XCTAssertNil(error)
            XCTAssertNotEqual(balance, tokenOwner)
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 10)
    }
    
    func test_GivenAddressWithTransfer_FindsTransferEvent() {
        let expect = expectation(description: "Events")
        
        erc721.transferEventsTo(recipient: tokenOwner,
                                fromBlock: .Number(
                                    5551315),
                                toBlock: .Number(
                                    5551315),
                                completion: { (error, events) in
            XCTAssertEqual(events?.first?.from, EthereumAddress.zero)
            XCTAssertEqual(events?.first?.to, tokenOwner)
            XCTAssertEqual(events?.first?.tokenId, 23)
            expect.fulfill()
        })
        
        waitForExpectations(timeout: 10)
    }
}

class ERC721MetadataTests: XCTestCase {
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
        XCTAssertEqual(ERC721Metadata.interfaceID.hexString, "0x5b5e139f")
    }
    
    func test_ReturnsName() {
        let expect = expectation(description: "name")
        erc721.name(contract: address) { (error, name) in
            XCTAssertNil(error)
            XCTAssertEqual(name, "Graph Art Token")
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 10)
    }
    
    func test_ReturnsSymbol() {
        let expect = expectation(description: "symbol")
        erc721.symbol(contract: address) { (error, symbol) in
            XCTAssertNil(error)
            XCTAssertEqual(symbol, "GAT")
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 10)
    }
    
    func test_ReturnsMetatadaURI() {
        let expect = expectation(description: "tokenURI")
        erc721.tokenURI(contract: address, tokenID: 23) { (error, url) in
            XCTAssertNil(error)
            XCTAssertEqual(url, nftURL)
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 10)
    }
    
    func test_ReturnsMetatada() {
        let expect = expectation(description: "tokenMetadata")
        erc721.tokenMetadata(contract: address, tokenID: 23) { (error, metadata) in
            XCTAssertNil(error)
            XCTAssertEqual(metadata, self.nftDetails)
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 10)
    }
}

class ERC721EnumerableTests: XCTestCase {
    var client: EthereumClient!
    var erc721: ERC721Enumerable!
    let address = EthereumAddress(TestConfig.erc721Contract)
    
    override func setUp() {
        super.setUp()
        self.client = EthereumClient(url: URL(string: TestConfig.clientUrl)!)
        self.erc721 = ERC721Enumerable(client: client)
    }
    
    func test_InterfaceIDMatch() {
        XCTAssertEqual(ERC721Enumerable.interfaceID.hexString, "0x780e9d63")
    }
    
    func test_returnsTotalSupply() {
        let expect = expectation(description: "totalSupply")
        erc721.totalSupply(contract: address) { (error, supply) in
            XCTAssertNil(error)
            XCTAssertGreaterThan(supply ?? 0, 22)
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 10)
    }
    
    func test_returnsTokenByIndex() {
        let expect = expectation(description: "tokenByIndex")
        erc721.tokenByIndex(contract: address, index: 22) { (error, index) in
            XCTAssertNil(error)
            XCTAssertEqual(index, 23)
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 10)
    }
    
    func test_GivenAddressWithNFT_returnsTokenOfOwnerByIndex() {
        let expect = expectation(description: "tokenByIndex")
        erc721.tokenOfOwnerByIndex(contract: address, owner: tokenOwner, index: 0) { error, tokenID in
            XCTAssertNil(error)
            XCTAssertEqual(tokenID, 23)
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 10)
    }
    
    func test_GivenAddressWithNoNFT_returnsIdZero() {
        let expect = expectation(description: "tokenByIndex")
        erc721.tokenOfOwnerByIndex(contract: address, owner: nonOwner, index: 0) { error, tokenID in
            XCTAssertNil(error)
            XCTAssertEqual(tokenID, 0)
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 10)
    }
}
