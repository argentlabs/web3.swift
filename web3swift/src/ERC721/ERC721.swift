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
                          completionHandler: @escaping(Result<BigUInt, Error>) -> Void) {
        let function = ERC721Functions.balanceOf(contract: contract, owner: address)
        function.call(withClient: client,
                      responseType: ERC721Responses.balanceResponse.self) { result in
            switch result {
            case .success(let data):
                completionHandler(.success(data.value))
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }

    public func ownerOf(contract: EthereumAddress,
                        tokenId: BigUInt,
                        completionHandler: @escaping(Result<EthereumAddress, Error>) -> Void) {
        let function = ERC721Functions.ownerOf(contract: contract, tokenId: tokenId)
        function.call(withClient: client,
                      responseType: ERC721Responses.ownerResponse.self)  { result in
            switch result {
            case .success(let data):
                completionHandler(.success(data.value))
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }

    public func transferEventsTo(recipient: EthereumAddress,
                                 fromBlock: EthereumBlock,
                                 toBlock: EthereumBlock,
                                 completionHandler: @escaping(Result<[ERC721Events.Transfer], Error>) -> Void) {
        guard let result = try? ABIEncoder.encode(recipient).bytes, let sig = try? ERC721Events.Transfer.signature() else {
            completionHandler(.failure(EthereumSignerError.unknownError))
            return
        }

        client.getEvents(addresses: nil,
                         topics: [ sig, nil, String(hexFromBytes: result)],
                         fromBlock: fromBlock,
                         toBlock: toBlock,
                         eventTypes: [ERC721Events.Transfer.self]) { result in

            switch result {
            case .success(let data):
                if let events = data.events as? [ERC721Events.Transfer] {
                    completionHandler(.success(events))
                } else {
                    completionHandler(.failure(EthereumClientError.decodeIssue))
                }
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }

    public func transferEventsFrom(sender: EthereumAddress,
                                   fromBlock: EthereumBlock,
                                   toBlock: EthereumBlock,
                                   completionHandler: @escaping(Result<[ERC721Events.Transfer], Error>) -> Void) {
        guard let result = try? ABIEncoder.encode(sender).bytes, let sig = try? ERC721Events.Transfer.signature() else {
            completionHandler(.failure(EthereumSignerError.unknownError))
            return
        }

        client.getEvents(addresses: nil,
                         topics: [ sig, String(hexFromBytes: result)],
                         fromBlock: fromBlock,
                         toBlock: toBlock,
                         eventTypes: [ERC721Events.Transfer.self]) { result in

            switch result {
            case .success(let data):
                if let events = data.events as? [ERC721Events.Transfer] {
                    completionHandler(.success(events))
                } else {
                    completionHandler(.failure(EthereumClientError.decodeIssue))
                }
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
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

    public init(client: EthereumClientProtocol, metadataSession: URLSession) {
        self.session = metadataSession
        super.init(client: client)
    }

    required init(client: EthereumClientProtocol) {
        fatalError("init(client:) has not been implemented")
    }

    public func name(contract: EthereumAddress,
                     completionHandler: @escaping(Result<String, Error>) -> Void) {
        let function = ERC721MetadataFunctions.name(contract: contract)
        function.call(withClient: client, responseType: ERC721MetadataResponses.nameResponse.self) { result in
            switch result {
            case .success(let data):
                completionHandler(.success(data.value))
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }

    public func symbol(contract: EthereumAddress,
                       completionHandler: @escaping(Result<String, Error>) -> Void) {
        let function = ERC721MetadataFunctions.symbol(contract: contract)
        function.call(withClient: client, responseType: ERC721MetadataResponses.symbolResponse.self) { result in
            switch result {
            case .success(let data):
                completionHandler(.success(data.value))
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }

    public func tokenURI(contract: EthereumAddress,
                         tokenID: BigUInt,
                         completionHandler: @escaping(Result<URL, Error>) -> Void) {
        let function = ERC721MetadataFunctions.tokenURI(contract: contract,
                                                        tokenID: tokenID)
        function.call(withClient: client, responseType: ERC721MetadataResponses.tokenURIResponse.self) { result in
            switch result {
            case .success(let data):
                completionHandler(.success(data.value))
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }

    public func tokenMetadata(contract: EthereumAddress,
                              tokenID: BigUInt,
                              completionHandler: @escaping(Result<Token, Error>) -> Void) {
        tokenURI(contract: contract,
                 tokenID: tokenID) { [weak self] result in
            switch result {
            case .success(let baseURL):
                let task = self?.session.dataTask(with: baseURL,
                                                  completionHandler: { (data, response, error) in
                    guard let data = data else {
                        completionHandler(.failure(EthereumClientError.unexpectedReturnValue))
                        return
                    }
                    if let error = error {
                        completionHandler(.failure(error))
                        return
                    }

                    do {
                        var metadata = try JSONDecoder().decode(Token.self, from: data)

                        if let image = metadata.properties?.image.description, image.host == nil, let relative = URL(string: image.absoluteString, relativeTo: baseURL) {
                            metadata.properties?.image = Token.Property(description: relative)
                        }
                        completionHandler(.success(metadata))
                    } catch let decodeError {
                        completionHandler(.failure(decodeError))
                    }
                })

                task?.resume()
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }
}

public class ERC721Enumerable: ERC721 {
    public func totalSupply(contract: EthereumAddress,
                            completionHandler: @escaping(Result<BigUInt, Error>) -> Void) {
        let function = ERC721EnumerableFunctions.totalSupply(contract: contract)
        function.call(withClient: client, responseType: ERC721EnumerableResponses.numberResponse.self) { result in
            switch result {
            case .success(let data):
                completionHandler(.success(data.value))
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }

    public func tokenByIndex(contract: EthereumAddress,
                             index: BigUInt,
                             completionHandler: @escaping(Result<BigUInt, Error>) -> Void) {
        let function = ERC721EnumerableFunctions.tokenByIndex(contract: contract, index: index)
        function.call(withClient: client, responseType: ERC721EnumerableResponses.numberResponse.self) { result in
            switch result {
            case .success(let data):
                completionHandler(.success(data.value))
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }

    public func tokenOfOwnerByIndex(contract: EthereumAddress,
                                    owner: EthereumAddress,
                                    index: BigUInt,
                                    completionHandler: @escaping(Result<BigUInt, Error>) -> Void) {
        let function = ERC721EnumerableFunctions.tokenOfOwnerByIndex(contract: contract, address: owner, index: index)
        function.call(withClient: client,
                      responseType: ERC721EnumerableResponses.numberResponse.self,
                      resolution: .noOffchain(failOnExecutionError: false)) { result in
            switch result {
            case .success(let data):
                completionHandler(.success(data.value))
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }
}

// MARK: - Async/Await
extension ERC721 {
    public func balanceOf(contract: EthereumAddress, address: EthereumAddress) async throws -> BigUInt {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<BigUInt, Error>) in
            balanceOf(contract: contract, address: address, completionHandler: continuation.resume)
        }
    }

    public func ownerOf(contract: EthereumAddress, tokenId: BigUInt) async throws -> EthereumAddress {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<EthereumAddress, Error>) in
            ownerOf(contract: contract, tokenId: tokenId, completionHandler: continuation.resume)
        }
    }

    public func transferEventsTo(recipient: EthereumAddress, fromBlock: EthereumBlock, toBlock: EthereumBlock) async throws -> [ERC721Events.Transfer] {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[ERC721Events.Transfer], Error>) in
            transferEventsTo(recipient: recipient, fromBlock: fromBlock, toBlock: toBlock, completionHandler: continuation.resume)
        }
    }

    public func transferEventsFrom(sender: EthereumAddress, fromBlock: EthereumBlock, toBlock: EthereumBlock) async throws -> [ERC721Events.Transfer] {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[ERC721Events.Transfer], Error>) in
            transferEventsFrom(sender: sender, fromBlock: fromBlock, toBlock: toBlock, completionHandler: continuation.resume)
        }
    }
}

extension ERC721Metadata {
    public func name(contract: EthereumAddress) async throws -> String {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            name(contract: contract, completionHandler: continuation.resume)
        }
    }

    public func symbol(contract: EthereumAddress) async throws -> String {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            symbol(contract: contract, completionHandler: continuation.resume)
        }
    }

    public func tokenURI(contract: EthereumAddress, tokenID: BigUInt) async throws -> URL {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
            tokenURI(contract: contract, tokenID: tokenID, completionHandler: continuation.resume)
        }
    }

    public func tokenMetadata(contract: EthereumAddress, tokenID: BigUInt) async throws -> Token {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Token, Error>) in
            tokenMetadata(contract: contract, tokenID: tokenID, completionHandler: continuation.resume)
        }
    }
}

extension ERC721Enumerable {
    public func totalSupply(contract: EthereumAddress) async throws -> BigUInt {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<BigUInt, Error>) in
            totalSupply(contract: contract, completionHandler: continuation.resume)
        }
    }

    public func tokenByIndex(contract: EthereumAddress, index: BigUInt) async throws -> BigUInt {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<BigUInt, Error>) in
            tokenByIndex(contract: contract, index: index, completionHandler: continuation.resume)
        }
    }

    public func tokenOfOwnerByIndex(contract: EthereumAddress, owner: EthereumAddress, index: BigUInt) async throws -> BigUInt {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<BigUInt, Error>) in
            tokenOfOwnerByIndex(contract: contract, owner: owner, index: index, completionHandler: continuation.resume)
        }
    }
}
