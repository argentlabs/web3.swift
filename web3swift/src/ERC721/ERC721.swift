//
//  ERC721.swift
//  web3swift
//
//  Created by Miguel on 09/05/2019.
//  Copyright © 2019 Argent Labs Limited. All rights reserved.
//

import Foundation
import BigInt

public class ERC721: ERC165 {
    
    @available(*, deprecated, message: "Prefer async alternative instead")
    public func balanceOf(contract: EthereumAddress,
                          address: EthereumAddress,
                          completion: @escaping((Error?, BigUInt?) -> Void)) {
        async {
            do {
                let result = try await balanceOf(contract: contract, address: address)
                completion(nil, result)
            } catch {
                completion(error, nil)
            }
        }
    }
    
    public func balanceOf(contract: EthereumAddress,
                          address: EthereumAddress) async throws -> BigUInt {
        let function = ERC721Functions.balanceOf(contract: contract, owner: address)
        let response = try await function.call(withClient: client, responseType: ERC721Responses.balanceResponse.self)
        return response.value
    }
    
    @available(*, deprecated, message: "Prefer async alternative instead")
    public func ownerOf(contract: EthereumAddress,
                        tokenId: BigUInt,
                        completion: @escaping((Error?, EthereumAddress?) -> Void)) {
        async {
            do {
                let result = try await ownerOf(contract: contract, tokenId: tokenId)
                completion(nil, result)
            } catch {
                completion(error, nil)
            }
        }
    }
    
    public func ownerOf(contract: EthereumAddress,
                        tokenId: BigUInt) async throws -> EthereumAddress {
        let function = ERC721Functions.ownerOf(contract: contract, tokenId: tokenId)
        let response = try await function.call(withClient: client, responseType: ERC721Responses.ownerResponse.self)
        return response.value
    }
    
    @available(*, deprecated, message: "Prefer async alternative instead")
    public func transferEventsTo(recipient: EthereumAddress,
                                 fromBlock: EthereumBlock,
                                 toBlock: EthereumBlock,
                                 completion: @escaping((Error?, [ERC721Events.Transfer]?) -> Void)) {
        async {
            do {
                let result = try await transferEventsTo(recipient: recipient, fromBlock: fromBlock, toBlock: toBlock)
                completion(nil, result)
            } catch {
                completion(error, nil)
            }
        }
    }
    
    
    public func transferEventsTo(recipient: EthereumAddress,
                                 fromBlock: EthereumBlock = .earliest,
                                 toBlock: EthereumBlock = .latest) async throws -> [ERC721Events.Transfer] {
        let result = try ABIEncoder.encode(recipient).bytes
        let sig = try ERC721Events.Transfer.signature()
        
        let (events, _) = try await client.getEvents(addresses: nil, topics: [ sig, nil, String(hexFromBytes: result)], fromBlock: fromBlock, toBlock: toBlock, eventTypes: [ERC721Events.Transfer.self])
        guard let events = events as? [ERC721Events.Transfer] else {
            throw EthereumClientError.decodeIssue
        }
        return events
    }
    
    @available(*, deprecated, message: "Prefer async alternative instead")
    public func transferEventsFrom(sender: EthereumAddress,
                                   fromBlock: EthereumBlock,
                                   toBlock: EthereumBlock,
                                   completion: @escaping((Error?, [ERC721Events.Transfer]?) -> Void)) {
        async {
            do {
                let result = try await transferEventsFrom(sender: sender, fromBlock: fromBlock, toBlock: toBlock)
                completion(nil, result)
            } catch {
                completion(error, nil)
            }
        }
    }    
    
    public func transferEventsFrom(sender: EthereumAddress,
                                   fromBlock: EthereumBlock,
                                   toBlock: EthereumBlock) async throws -> [ERC721Events.Transfer] {
        let result = try ABIEncoder.encode(sender).bytes
        let sig = try ERC721Events.Transfer.signature()
        
        let (events, _) = try await client.getEvents(addresses: nil, topics: [ sig, String(hexFromBytes: result)], fromBlock: fromBlock, toBlock: toBlock, eventTypes: [ERC721Events.Transfer.self])
        guard let events = events as? [ERC721Events.Transfer] else {
            throw EthereumClientError.decodeIssue
        }
        return events
    }
}

public class ERC721Metadata: ERC721 {
    public struct Token: Equatable, Decodable {
        public typealias PropertyType = Equatable & Decodable
        public struct Property<T: PropertyType>: Equatable, Decodable {
            public var description: T
        }
        
        enum CodingKeys: String, CodingKey {
            case title
            case type
            case properties
            case fallback_property_image = "image"
            case fallback_property_description = "description"
            case fallback_property_name = "name"
        }
        
        public init(title: String?,
                    type: String?,
                    properties: Properties?) {
            self.title = title
            self.type = type
            self.properties = properties
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.title = try? container.decode(String.self, forKey: .title)
            self.type = try? container.decode(String.self, forKey: .type)
            let properties = try? container.decode(Properties.self, forKey: .properties)
            
            if let properties = properties {
                self.properties = properties
            } else {
                // try decoding properties from root directly
                let name = try? container.decode(String.self, forKey: .fallback_property_name)
                let image = try? container.decode(URL.self, forKey: .fallback_property_image)
                let description = try? container.decode(String.self, forKey: .fallback_property_description)
                if name != nil || image != nil || description != nil {
                    self.properties = Properties(name: Property(description: name),
                                                 description: Property(description: description),
                                                 image: Property(description: image))
                } else {
                    self.properties = nil
                }
            }
        }
        
        public struct Properties: Equatable, Decodable {
            public var name: Property<String?>
            public var description: Property<String?>
            public var image: Property<URL?>
        }
        
        public var title: String?
        public var type: String?
        public var properties: Properties?
    }
    
    public let session: URLSession
    
    public init(client: EthereumClient, metadataSession: URLSession) {
        self.session = metadataSession
        super.init(client: client)
    }
    
    @available(*, deprecated, message: "Prefer async alternative instead")
    public func name(contract: EthereumAddress,
                     completion: @escaping((Error?, String?) -> Void)) {
        async {
            do {
                let result = try await name(contract: contract)
                completion(nil, result)
            } catch {
                completion(error, nil)
            }
        }
    }
        
    public func name(contract: EthereumAddress) async throws -> String {
        let function = ERC721MetadataFunctions.name(contract: contract)
        let response = try await function.call(withClient: client, responseType: ERC721MetadataResponses.nameResponse.self)
        return response.value
    }
    
    @available(*, deprecated, message: "Prefer async alternative instead")
    public func symbol(contract: EthereumAddress,
                       completion: @escaping((Error?, String?) -> Void)) {
        async {
            do {
                let result = try await symbol(contract: contract)
                completion(nil, result)
            } catch {
                completion(error, nil)
            }
        }
    }
        
    public func symbol(contract: EthereumAddress) async throws -> String {
        let function = ERC721MetadataFunctions.symbol(contract: contract)
        let response = try await function.call(withClient: client, responseType: ERC721MetadataResponses.symbolResponse.self)
        return response.value
    }
    
    @available(*, deprecated, message: "Prefer async alternative instead")
    public func tokenURI(contract: EthereumAddress,
                         tokenID: BigUInt,
                         completion: @escaping((Error?, URL?) -> Void)) {
        async {
            do {
                let result = try await tokenURI(contract: contract, tokenID: tokenID)
                completion(nil, result)
            } catch {
                completion(error, nil)
            }
        }
    }
    
    public func tokenURI(contract: EthereumAddress,
                         tokenID: BigUInt) async throws -> URL {
        let function = ERC721MetadataFunctions.tokenURI(contract: contract,
                                                        tokenID: tokenID)
        let response = try await function.call(withClient: client, responseType: ERC721MetadataResponses.tokenURIResponse.self)
        return response.value
    }
    
    @available(*, deprecated, message: "Prefer async alternative instead")
    public func tokenMetadata(contract: EthereumAddress,
                              tokenID: BigUInt,
                              completion: @escaping((Error?, Token?) -> Void)) {
        async {
            do {
                let result = try await tokenMetadata(contract: contract, tokenID: tokenID)
                completion(nil, result)
            } catch {
                completion(error, nil)
            }
        }
    }
        
    public func tokenMetadata(contract: EthereumAddress,
                              tokenID: BigUInt) async throws -> ERC721Metadata.Token {
        let baseURL = try await tokenURI(contract: contract, tokenID: tokenID)
        let (data, _) = try await session.data(from: baseURL)
        var metadata = try JSONDecoder().decode(Token.self, from: data)
        if let image = metadata.properties?.image.description, image.host == nil, let relative = URL(string: image.absoluteString, relativeTo: baseURL) {
            metadata.properties?.image = Token.Property(description: relative)
        }
        return metadata
    }
}

public class ERC721Enumerable: ERC721 {
    
    @available(*, deprecated, message: "Prefer async alternative instead")
    public func totalSupply(contract: EthereumAddress,
                            completion: @escaping((Error?, BigUInt?) -> Void)) {
        async {
            do {
                let result = try await totalSupply(contract: contract)
                completion(nil, result)
            } catch {
                completion(error, nil)
            }
        }
    }
    
    public func totalSupply(contract: EthereumAddress) async throws -> BigUInt {
        let function = ERC721EnumerableFunctions.totalSupply(contract: contract)
        let response = try await function.call(withClient: client, responseType: ERC721EnumerableResponses.numberResponse.self)
        return response.value
    }
    
    @available(*, deprecated, message: "Prefer async alternative instead")
    public func tokenByIndex(contract: EthereumAddress,
                             index: BigUInt,
                             completion: @escaping((Error?, BigUInt?) -> Void)) {
        async {
            do {
                let result = try await tokenByIndex(contract: contract, index: index)
                completion(nil, result)
            } catch {
                completion(error, nil)
            }
        }
    }
        
    public func tokenByIndex(contract: EthereumAddress,
                             index: BigUInt) async throws -> BigUInt {
        let function = ERC721EnumerableFunctions.tokenByIndex(contract: contract, index: index)
        let response = try await function.call(withClient: client, responseType: ERC721EnumerableResponses.numberResponse.self)
        return response.value
    }
    
    @available(*, deprecated, message: "Prefer async alternative instead")
    public func tokenOfOwnerByIndex(contract: EthereumAddress,
                                    owner: EthereumAddress,
                                    index: BigUInt,
                                    completion: @escaping((Error?, BigUInt?) -> Void)) {
        async {
            do {
                let result = try await tokenOfOwnerByIndex(contract: contract, owner: owner, index: index)
                completion(nil, result)
            } catch {
                completion(error, nil)
            }
        }
    }
        
    public func tokenOfOwnerByIndex(contract: EthereumAddress,
                                    owner: EthereumAddress,
                                    index: BigUInt) async throws -> BigUInt {
        let function = ERC721EnumerableFunctions.tokenOfOwnerByIndex(contract: contract, address: owner, index: index)
        let response = try await function.call(withClient: client, responseType: ERC721EnumerableResponses.numberResponse.self)
        return response.value
    }
}
