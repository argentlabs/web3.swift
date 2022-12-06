//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import BigInt
import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

open class ERC721: ERC165 {
    public func balanceOf(contract: EthereumAddress, address: EthereumAddress) async throws -> BigUInt {
        let function = ERC721Functions.balanceOf(contract: contract, owner: address)
        let data = try await function.call(withClient: client, responseType: ERC721Responses.balanceResponse.self)

        return data.value
    }

    public func ownerOf(contract: EthereumAddress, tokenId: BigUInt) async throws -> EthereumAddress {
        let function = ERC721Functions.ownerOf(contract: contract, tokenId: tokenId)
        let data = try await function.call(withClient: client, responseType: ERC721Responses.ownerResponse.self)

        return data.value
    }

    public func transferEventsTo(recipient: EthereumAddress, fromBlock: EthereumBlock, toBlock: EthereumBlock) async throws -> [ERC721Events.Transfer] {
        guard let result = try? ABIEncoder.encode(recipient).bytes, let sig = try? ERC721Events.Transfer.signature() else {
            throw EthereumSignerError.unknownError
        }

        let data = try await client.getEvents(
            addresses: nil,
            topics: [sig, nil, String(hexFromBytes: result)],
            fromBlock: fromBlock,
            toBlock: toBlock,
            eventTypes: [ERC721Events.Transfer.self]
        )

        if let events = data.events as? [ERC721Events.Transfer] {
            return events
        } else {
            throw EthereumClientError.decodeIssue
        }
    }

    public func transferEventsFrom(sender: EthereumAddress, fromBlock: EthereumBlock, toBlock: EthereumBlock) async throws -> [ERC721Events.Transfer] {
        guard let result = try? ABIEncoder.encode(sender).bytes, let sig = try? ERC721Events.Transfer.signature() else {
            throw EthereumSignerError.unknownError
        }

        let data = try await client.getEvents(
            addresses: nil,
            topics: [sig, String(hexFromBytes: result)],
            fromBlock: fromBlock,
            toBlock: toBlock,
            eventTypes: [ERC721Events.Transfer.self]
        )

        if let events = data.events as? [ERC721Events.Transfer] {
            return events
        } else {
            throw EthereumClientError.decodeIssue
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

        public init(
            title: String?,
            type: String?,
            properties: Properties?
        ) {
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
                    self.properties = Properties(
                        name: Property(description: name),
                        description: Property(description: description),
                        image: Property(description: image)
                    )
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

    public func name(contract: EthereumAddress) async throws -> String {
        let function = ERC721MetadataFunctions.name(contract: contract)
        let data = try await function.call(withClient: client, responseType: ERC721MetadataResponses.nameResponse.self)

        return data.value
    }

    public func symbol(contract: EthereumAddress) async throws -> String {
        let function = ERC721MetadataFunctions.symbol(contract: contract)
        let data = try await function.call(withClient: client, responseType: ERC721MetadataResponses.symbolResponse.self)

        return data.value
    }

    public func tokenURI(contract: EthereumAddress, tokenID: BigUInt) async throws -> URL {
        let function = ERC721MetadataFunctions.tokenURI(contract: contract, tokenID: tokenID)
        let data = try await function.call(withClient: client, responseType: ERC721MetadataResponses.tokenURIResponse.self)

        return data.value
    }

    public func tokenMetadata(contract: EthereumAddress, tokenID: BigUInt) async throws -> Token {
        let baseURL = try await tokenURI(contract: contract, tokenID: tokenID)

        guard let (data, _) = try? await session.data(from: baseURL) else {
            throw EthereumClientError.unexpectedReturnValue
        }

        do {
            var metadata = try JSONDecoder().decode(Token.self, from: data)

            if let image = metadata.properties?.image.description, image.host == nil, let relative = URL(string: image.absoluteString, relativeTo: baseURL) {
                metadata.properties?.image = Token.Property(description: relative)
            }
            return metadata
        } catch let decodeError {
            throw decodeError
        }
    }
}

public class ERC721Enumerable: ERC721 {
    public func totalSupply(contract: EthereumAddress) async throws -> BigUInt {
        let function = ERC721EnumerableFunctions.totalSupply(contract: contract)
        let data = try await function.call(withClient: client, responseType: ERC721EnumerableResponses.numberResponse.self)

        return data.value
    }

    public func tokenByIndex(contract: EthereumAddress, index: BigUInt) async throws -> BigUInt {
        let function = ERC721EnumerableFunctions.tokenByIndex(contract: contract, index: index)
        let data = try await function.call(withClient: client, responseType: ERC721EnumerableResponses.numberResponse.self)

        return data.value
    }

    public func tokenOfOwnerByIndex(contract: EthereumAddress, owner: EthereumAddress, index: BigUInt) async throws -> BigUInt {
        let function = ERC721EnumerableFunctions.tokenOfOwnerByIndex(contract: contract, address: owner, index: index)
        let data = try await function.call(
            withClient: client,
            responseType: ERC721EnumerableResponses.numberResponse.self,
            resolution: .noOffchain(failOnExecutionError: false)
        )

        return data.value
    }
}

extension ERC721 {
    public func balanceOf(
        contract: EthereumAddress,
        address: EthereumAddress,
        completionHandler: @escaping (Result<BigUInt, Error>) -> Void
    ) {
        Task {
            do {
                let balance = try await balanceOf(contract: contract, address: address)
                completionHandler(.success(balance))
            } catch {
                completionHandler(.failure(error))
            }
        }
    }

    public func ownerOf(
        contract: EthereumAddress,
        tokenId: BigUInt,
        completionHandler: @escaping (Result<EthereumAddress, Error>) -> Void
    ) {
        Task {
            do {
                let ownerOf = try await ownerOf(contract: contract, tokenId: tokenId)
                completionHandler(.success(ownerOf))
            } catch {
                completionHandler(.failure(error))
            }
        }
    }

    public func transferEventsTo(
        recipient: EthereumAddress,
        fromBlock: EthereumBlock,
        toBlock: EthereumBlock,
        completionHandler: @escaping (Result<[ERC721Events.Transfer], Error>) -> Void
    ) {
        Task {
            do {
                let result = try await transferEventsTo(recipient: recipient, fromBlock: fromBlock, toBlock: toBlock)
                completionHandler(.success(result))
            } catch {
                completionHandler(.failure(error))
            }
        }
    }

    public func transferEventsFrom(
        sender: EthereumAddress,
        fromBlock: EthereumBlock,
        toBlock: EthereumBlock,
        completionHandler: @escaping (Result<[ERC721Events.Transfer], Error>) -> Void
    ) {
        Task {
            do {
                let result = try await transferEventsFrom(sender: sender, fromBlock: fromBlock, toBlock: toBlock)
                completionHandler(.success(result))
            } catch {
                completionHandler(.failure(error))
            }
        }
    }
}

extension ERC721Metadata {
    public func name(
        contract: EthereumAddress,
        completionHandler: @escaping (Result<String, Error>) -> Void
    ) {
        Task {
            do {
                let result = try await name(contract: contract)
                completionHandler(.success(result))
            } catch {
                completionHandler(.failure(error))
            }
        }
    }

    public func symbol(
        contract: EthereumAddress,
        completionHandler: @escaping (Result<String, Error>) -> Void
    ) {
        Task {
            do {
                let result = try await symbol(contract: contract)
                completionHandler(.success(result))
            } catch {
                completionHandler(.failure(error))
            }
        }
    }

    public func tokenURI(
        contract: EthereumAddress,
        tokenID: BigUInt,
        completionHandler: @escaping (Result<URL, Error>) -> Void
    ) {
        Task {
            do {
                let result = try await tokenURI(contract: contract, tokenID: tokenID)
                completionHandler(.success(result))
            } catch {
                completionHandler(.failure(error))
            }
        }
    }

    public func tokenMetadata(
        contract: EthereumAddress,
        tokenID: BigUInt,
        completionHandler: @escaping (Result<Token, Error>) -> Void
    ) {
        Task {
            do {
                let result = try await tokenMetadata(contract: contract, tokenID: tokenID)
                completionHandler(.success(result))
            } catch {
                completionHandler(.failure(error))
            }
        }
    }
}

extension ERC721Enumerable {
    public func totalSupply(
        contract: EthereumAddress,
        completionHandler: @escaping (Result<BigUInt, Error>) -> Void
    ) {
        Task {
            do {
                let result = try await totalSupply(contract: contract)
                completionHandler(.success(result))
            } catch {
                completionHandler(.failure(error))
            }
        }
    }

    public func tokenByIndex(
        contract: EthereumAddress,
        index: BigUInt,
        completionHandler: @escaping (Result<BigUInt, Error>) -> Void
    ) {
        Task {
            do {
                let result = try await tokenByIndex(contract: contract, index: index)
                completionHandler(.success(result))
            } catch {
                completionHandler(.failure(error))
            }
        }
    }

    public func tokenOfOwnerByIndex(
        contract: EthereumAddress,
        owner: EthereumAddress,
        index: BigUInt,
        completionHandler: @escaping (Result<BigUInt, Error>) -> Void
    ) {
        Task {
            do {
                let result = try await tokenOfOwnerByIndex(contract: contract, owner: owner, index: index)
                completionHandler(.success(result))
            } catch {
                completionHandler(.failure(error))
            }
        }
    }
}
