//
//  ERC721.swift
//  web3swift
//
//  Created by Miguel on 09/05/2019.
//  Copyright © 2019 Argent Labs Limited. All rights reserved.
//

import Foundation
import BigInt

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public class ERC721: ERC165 {
    public func balanceOf(contract: EthereumAddress,
                          address: EthereumAddress,
                          completion: @escaping((Error?, BigUInt?) -> Void)) {
        let function = ERC721Functions.balanceOf(contract: contract, owner: address)
        function.call(withClient: client,
                      responseType: ERC721Responses.balanceResponse.self) { (error, response) in
            return completion(error, response?.value)
        }
    }

    public func ownerOf(contract: EthereumAddress,
                        tokenId: BigUInt,
                        completion: @escaping((Error?, EthereumAddress?) -> Void)) {
        let function = ERC721Functions.ownerOf(contract: contract, tokenId: tokenId)
        function.call(withClient: client,
                      responseType: ERC721Responses.ownerResponse.self) { (error, response) in
            return completion(error, response?.value)
        }
    }

    public func transferEventsTo(recipient: EthereumAddress,
                                 fromBlock: EthereumBlock,
                                 toBlock: EthereumBlock,
                                 completion: @escaping((Error?, [ERC721Events.Transfer]?) -> Void)) {
        guard let result = try? ABIEncoder.encode(recipient).bytes, let sig = try? ERC721Events.Transfer.signature() else {
            completion(EthereumSignerError.unknownError, nil)
            return
        }

        client.getEvents(addresses: nil,
                         topics: [ sig, nil, String(hexFromBytes: result)],
                         fromBlock: fromBlock,
                         toBlock: toBlock,
                         eventTypes: [ERC721Events.Transfer.self]) { (error, events, unprocessedLogs) in

            if let events = events as? [ERC721Events.Transfer] {
                return completion(error, events)
            } else {
                return completion(error ?? EthereumClientError.decodeIssue, nil)
            }
        }
    }

    public func transferEventsFrom(sender: EthereumAddress,
                                   fromBlock: EthereumBlock,
                                   toBlock: EthereumBlock,
                                   completion: @escaping((Error?, [ERC721Events.Transfer]?) -> Void)) {
        guard let result = try? ABIEncoder.encode(sender).bytes, let sig = try? ERC721Events.Transfer.signature() else {
            completion(EthereumSignerError.unknownError, nil)
            return
        }

        client.getEvents(addresses: nil,
                         topics: [ sig, String(hexFromBytes: result)],
                         fromBlock: fromBlock,
                         toBlock: toBlock,
                         eventTypes: [ERC721Events.Transfer.self]) { (error, events, unprocessedLogs) in

            if let events = events as? [ERC721Events.Transfer] {
                return completion(error, events)
            } else {
                return completion(error ?? EthereumClientError.decodeIssue, nil)
            }
        }
    }
}

#if compiler(>=5.5) && canImport(_Concurrency)

@available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
extension ERC721 {
    public func balanceOf(contract: EthereumAddress, address: EthereumAddress) async throws -> BigUInt {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<BigUInt, Error>) in
            balanceOf(contract: contract, address: address) { error, balance in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let balance = balance {
                    continuation.resume(returning: balance)
                }
            }
        }
    }

    public func ownerOf(contract: EthereumAddress, tokenId: BigUInt) async throws -> EthereumAddress {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<EthereumAddress, Error>) in
            ownerOf(contract: contract, tokenId: tokenId) { error, owner in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let owner = owner {
                    continuation.resume(returning: owner)
                }
            }
        }
    }

    public func transferEventsTo(recipient: EthereumAddress, fromBlock: EthereumBlock, toBlock: EthereumBlock) async throws -> [ERC721Events.Transfer] {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[ERC721Events.Transfer], Error>) in
            transferEventsTo(recipient: recipient, fromBlock: fromBlock, toBlock: toBlock) { error, events in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let events = events {
                    continuation.resume(returning: events)
                }
            }
        }
    }

    public func transferEventsFrom(sender: EthereumAddress, fromBlock: EthereumBlock, toBlock: EthereumBlock) async throws -> [ERC721Events.Transfer] {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[ERC721Events.Transfer], Error>) in
            transferEventsFrom(sender: sender, fromBlock: fromBlock, toBlock: toBlock) { error, events in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let events = events {
                    continuation.resume(returning: events)
                }
            }
        }
    }
}
#endif

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

    public init(client: EthereumClientProtocol, metadataSession: URLSession) {
        self.session = metadataSession
        super.init(client: client)
    }

    required init(client: EthereumClientProtocol) {
        fatalError("init(client:) has not been implemented")
    }

    public func name(contract: EthereumAddress,
                     completion: @escaping((Error?, String?) -> Void)) {
        let function = ERC721MetadataFunctions.name(contract: contract)
        function.call(withClient: client, responseType: ERC721MetadataResponses.nameResponse.self) { error, response in
            return completion(error, response?.value)
        }
    }

    public func symbol(contract: EthereumAddress,
                       completion: @escaping((Error?, String?) -> Void)) {
        let function = ERC721MetadataFunctions.symbol(contract: contract)
        function.call(withClient: client, responseType: ERC721MetadataResponses.symbolResponse.self) { error, response in
            return completion(error, response?.value)
        }
    }

    public func tokenURI(contract: EthereumAddress,
                         tokenID: BigUInt,
                         completion: @escaping((Error?, URL?) -> Void)) {
        let function = ERC721MetadataFunctions.tokenURI(contract: contract,
                                                        tokenID: tokenID)
        function.call(withClient: client, responseType: ERC721MetadataResponses.tokenURIResponse.self) { error, response in
            return completion(error, response?.value)
        }
    }

    public func tokenMetadata(contract: EthereumAddress,
                              tokenID: BigUInt,
                              completion: @escaping((Error?, Token?) -> Void)) {
        tokenURI(contract: contract,
                 tokenID: tokenID) { [weak self] error, response in
            guard let response = response else {
                return completion(error, nil)
            }

            if let error = error {
                return completion(error, nil)
            }

            let baseURL = response
            let task = self?.session.dataTask(with: baseURL,
                                              completionHandler: { (data, response, error) in
                guard let data = data else {
                    return completion(error, nil)
                }
                if let error = error {
                    return completion(error, nil)
                }

                do {
                    var metadata = try JSONDecoder().decode(Token.self, from: data)

                    if let image = metadata.properties?.image.description, image.host == nil, let relative = URL(string: image.absoluteString, relativeTo: baseURL) {
                        metadata.properties?.image = Token.Property(description: relative)
                    }
                    completion(nil, metadata)
                } catch let decodeError {
                    completion(decodeError, nil)
                }
            })

            task?.resume()
        }
    }
}

#if compiler(>=5.5) && canImport(_Concurrency)

@available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
extension ERC721Metadata {
    public func name(contract: EthereumAddress) async throws -> String {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            name(contract: contract) { error, name in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let name = name {
                    continuation.resume(returning: name)
                }
            }
        }
    }

    public func symbol(contract: EthereumAddress) async throws -> String {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            symbol(contract: contract) { error, symbol in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let symbol = symbol {
                    continuation.resume(returning: symbol)
                }
            }
        }
    }

    public func tokenURI(contract: EthereumAddress, tokenID: BigUInt) async throws -> URL {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
            tokenURI(contract: contract, tokenID: tokenID) { error, tokenURI in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let tokenURI = tokenURI {
                    continuation.resume(returning: tokenURI)
                }
            }
        }
    }

    public func tokenMetadata(contract: EthereumAddress, tokenID: BigUInt) async throws -> Token {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Token, Error>) in
            tokenMetadata(contract: contract, tokenID: tokenID) { error, tokenMetadata in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let tokenMetadata = tokenMetadata {
                    continuation.resume(returning: tokenMetadata)
                }
            }
        }
    }
}
#endif

public class ERC721Enumerable: ERC721 {
    public func totalSupply(contract: EthereumAddress,
                            completion: @escaping((Error?, BigUInt?) -> Void)) {
        let function = ERC721EnumerableFunctions.totalSupply(contract: contract)
        function.call(withClient: client, responseType: ERC721EnumerableResponses.numberResponse.self) { error, response in
            return completion(error, response?.value)
        }
    }

    public func tokenByIndex(contract: EthereumAddress,
                             index: BigUInt,
                             completion: @escaping((Error?, BigUInt?) -> Void)) {
        let function = ERC721EnumerableFunctions.tokenByIndex(contract: contract, index: index)
        function.call(withClient: client, responseType: ERC721EnumerableResponses.numberResponse.self) { error, response in
            return completion(error, response?.value)
        }
    }

    public func tokenOfOwnerByIndex(contract: EthereumAddress,
                                    owner: EthereumAddress,
                                    index: BigUInt,
                                    completion: @escaping((Error?, BigUInt?) -> Void)) {
        let function = ERC721EnumerableFunctions.tokenOfOwnerByIndex(contract: contract, address: owner, index: index)
        function.call(
            withClient: client,
            responseType: ERC721EnumerableResponses.numberResponse.self,
            resolution: .noOffchain(failOnExecutionError: false)
        ) { error, response in
            return completion(error, response?.value)
        }
    }
}

#if compiler(>=5.5) && canImport(_Concurrency)

@available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
extension ERC721Enumerable {
    public func totalSupply(contract: EthereumAddress) async throws -> BigUInt {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<BigUInt, Error>) in
            totalSupply(contract: contract) { error, totalSupply in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let totalSupply = totalSupply {
                    continuation.resume(returning: totalSupply)
                }
            }
        }
    }

    public func tokenByIndex(contract: EthereumAddress, index: BigUInt) async throws -> BigUInt {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<BigUInt, Error>) in
            tokenByIndex(contract: contract, index: index) { error, token in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let token = token {
                    continuation.resume(returning: token)
                }
            }
        }
    }

    public func tokenOfOwnerByIndex(contract: EthereumAddress, owner: EthereumAddress, index: BigUInt) async throws -> BigUInt {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<BigUInt, Error>) in
            tokenOfOwnerByIndex(contract: contract, owner: owner, index: index) { error, token in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let token = token {
                    continuation.resume(returning: token)
                }
            }
        }
    }
}
#endif
