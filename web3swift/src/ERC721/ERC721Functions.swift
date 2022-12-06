//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import BigInt
import Foundation

public enum ERC721Functions {
    public static var interfaceId: Data {
        "0x80ac58cd".web3.hexData!
    }

    public struct balanceOf: ABIFunction {
        public static let name = "balanceOf"
        public let gasPrice: BigUInt?
        public let gasLimit: BigUInt?
        public var contract: EthereumAddress
        public let from: EthereumAddress?

        public let owner: EthereumAddress

        public init(
            contract: EthereumAddress,
            from: EthereumAddress? = nil,
            owner: EthereumAddress,
            gasPrice: BigUInt? = nil,
            gasLimit: BigUInt? = nil
        ) {
            self.contract = contract
            self.from = from
            self.owner = owner
            self.gasPrice = gasPrice
            self.gasLimit = gasLimit
        }

        public func encode(to encoder: ABIFunctionEncoder) throws {
            try encoder.encode(owner)
        }
    }

    public struct ownerOf: ABIFunction {
        public static let name = "ownerOf"
        public let gasPrice: BigUInt?
        public let gasLimit: BigUInt?
        public var contract: EthereumAddress
        public let from: EthereumAddress?

        public let tokenId: BigUInt

        public init(
            contract: EthereumAddress,
            from: EthereumAddress? = nil,
            tokenId: BigUInt,
            gasPrice: BigUInt? = nil,
            gasLimit: BigUInt? = nil
        ) {
            self.contract = contract
            self.from = from
            self.tokenId = tokenId
            self.gasPrice = gasPrice
            self.gasLimit = gasLimit
        }

        public func encode(to encoder: ABIFunctionEncoder) throws {
            try encoder.encode(tokenId)
        }
    }

    public struct transferFrom: ABIFunction {
        public static let name = "transferFrom"
        public let gasPrice: BigUInt?
        public let gasLimit: BigUInt?
        public var contract: EthereumAddress
        public let from: EthereumAddress?

        public let sender: EthereumAddress
        public let to: EthereumAddress
        public let tokenId: BigUInt

        public init(
            contract: EthereumAddress,
            from: EthereumAddress? = nil,
            gasPrice: BigUInt? = nil,
            gasLimit: BigUInt? = nil,
            sender: EthereumAddress,
            to: EthereumAddress,
            tokenId: BigUInt
        ) {
            self.contract = contract
            self.from = from
            self.gasPrice = gasPrice
            self.gasLimit = gasLimit
            self.sender = sender
            self.to = to
            self.tokenId = tokenId
        }

        public func encode(to encoder: ABIFunctionEncoder) throws {
            try encoder.encode(sender)
            try encoder.encode(to)
            try encoder.encode(tokenId)
        }
    }

    public struct safeTransferFrom: ABIFunction {
        public static let name = "safeTransferFrom"
        public let gasPrice: BigUInt?
        public let gasLimit: BigUInt?
        public var contract: EthereumAddress
        public let from: EthereumAddress?

        public let sender: EthereumAddress
        public let to: EthereumAddress
        public let tokenId: BigUInt

        public init(
            contract: EthereumAddress,
            from: EthereumAddress? = nil,
            gasPrice: BigUInt? = nil,
            gasLimit: BigUInt? = nil,
            sender: EthereumAddress,
            to: EthereumAddress,
            tokenId: BigUInt
        ) {
            self.contract = contract
            self.from = from
            self.gasPrice = gasPrice
            self.gasLimit = gasLimit
            self.sender = sender
            self.to = to
            self.tokenId = tokenId
        }

        public func encode(to encoder: ABIFunctionEncoder) throws {
            try encoder.encode(sender)
            try encoder.encode(to)
            try encoder.encode(tokenId)
        }
    }

    public struct safeTransferFromAndData: ABIFunction {
        public static let name = "safeTransferFrom"
        public let gasPrice: BigUInt?
        public let gasLimit: BigUInt?
        public var contract: EthereumAddress
        public let from: EthereumAddress?

        public let sender: EthereumAddress
        public let to: EthereumAddress
        public let tokenId: BigUInt
        public let data: Data

        public init(
            contract: EthereumAddress,
            from: EthereumAddress? = nil,
            gasPrice: BigUInt? = nil,
            gasLimit: BigUInt? = nil,
            sender: EthereumAddress,
            to: EthereumAddress,
            tokenId: BigUInt,
            data: Data
        ) {
            self.contract = contract
            self.from = from
            self.gasPrice = gasPrice
            self.gasLimit = gasLimit
            self.sender = sender
            self.to = to
            self.tokenId = tokenId
            self.data = data
        }

        public func encode(to encoder: ABIFunctionEncoder) throws {
            try encoder.encode(sender)
            try encoder.encode(to)
            try encoder.encode(tokenId)
            try encoder.encode(data)
        }
    }
}

public enum ERC721MetadataFunctions {
    public static var interfaceId: Data {
        "name()".web3.keccak256.web3.bytes4 ^
            "symbol()".web3.keccak256.web3.bytes4 ^
            "tokenURI(uint256)".web3.keccak256.web3.bytes4
    }

    public struct name: ABIFunction {
        public static let name = "name"
        public let gasPrice: BigUInt?
        public let gasLimit: BigUInt?
        public var contract: EthereumAddress
        public let from: EthereumAddress?

        public init(
            contract: EthereumAddress,
            from: EthereumAddress? = nil,
            gasPrice: BigUInt? = nil,
            gasLimit: BigUInt? = nil
        ) {
            self.contract = contract
            self.from = from
            self.gasPrice = gasPrice
            self.gasLimit = gasLimit
        }

        public func encode(to encoder: ABIFunctionEncoder) throws {}
    }

    public struct symbol: ABIFunction {
        public static let name = "symbol"
        public let gasPrice: BigUInt?
        public let gasLimit: BigUInt?
        public var contract: EthereumAddress
        public let from: EthereumAddress?

        public init(
            contract: EthereumAddress,
            from: EthereumAddress? = nil,
            gasPrice: BigUInt? = nil,
            gasLimit: BigUInt? = nil
        ) {
            self.contract = contract
            self.from = from
            self.gasPrice = gasPrice
            self.gasLimit = gasLimit
        }

        public func encode(to encoder: ABIFunctionEncoder) throws {}
    }

    public struct tokenURI: ABIFunction {
        public static let name = "tokenURI"
        public let gasPrice: BigUInt?
        public let gasLimit: BigUInt?
        public var contract: EthereumAddress
        public let from: EthereumAddress?

        public let tokenID: BigUInt

        public init(
            contract: EthereumAddress,
            from: EthereumAddress? = nil,
            tokenID: BigUInt,
            gasPrice: BigUInt? = nil,
            gasLimit: BigUInt? = nil
        ) {
            self.contract = contract
            self.from = from
            self.tokenID = tokenID
            self.gasPrice = gasPrice
            self.gasLimit = gasLimit
        }

        public func encode(to encoder: ABIFunctionEncoder) throws {
            try encoder.encode(tokenID)
        }
    }
}

public enum ERC721EnumerableFunctions {
    public static var interfaceId: Data {
        "totalSupply()".web3.keccak256.web3.bytes4 ^
            "tokenByIndex(uint256)".web3.keccak256.web3.bytes4 ^
            "tokenOfOwnerByIndex(address,uint256)".web3.keccak256.web3.bytes4
    }

    public struct totalSupply: ABIFunction {
        public static let name = "totalSupply"
        public let gasPrice: BigUInt?
        public let gasLimit: BigUInt?
        public var contract: EthereumAddress
        public let from: EthereumAddress?

        public init(
            contract: EthereumAddress,
            from: EthereumAddress? = nil,
            gasPrice: BigUInt? = nil,
            gasLimit: BigUInt? = nil
        ) {
            self.contract = contract
            self.from = from
            self.gasPrice = gasPrice
            self.gasLimit = gasLimit
        }

        public func encode(to encoder: ABIFunctionEncoder) throws {}
    }

    public struct tokenByIndex: ABIFunction {
        public static let name = "tokenByIndex"
        public let gasPrice: BigUInt?
        public let gasLimit: BigUInt?
        public var contract: EthereumAddress
        public let from: EthereumAddress?

        public let index: BigUInt

        public init(
            contract: EthereumAddress,
            from: EthereumAddress? = nil,
            index: BigUInt,
            gasPrice: BigUInt? = nil,
            gasLimit: BigUInt? = nil
        ) {
            self.contract = contract
            self.from = from
            self.index = index
            self.gasPrice = gasPrice
            self.gasLimit = gasLimit
        }

        public func encode(to encoder: ABIFunctionEncoder) throws {
            try encoder.encode(index)
        }
    }

    public struct tokenOfOwnerByIndex: ABIFunction {
        public static let name = "tokenOfOwnerByIndex"
        public let gasPrice: BigUInt?
        public let gasLimit: BigUInt?
        public var contract: EthereumAddress
        public let from: EthereumAddress?

        public let address: EthereumAddress
        public let index: BigUInt

        public init(
            contract: EthereumAddress,
            from: EthereumAddress? = nil,
            address: EthereumAddress,
            index: BigUInt,
            gasPrice: BigUInt? = nil,
            gasLimit: BigUInt? = nil
        ) {
            self.contract = contract
            self.from = from
            self.address = address
            self.index = index
            self.gasPrice = gasPrice
            self.gasLimit = gasLimit
        }

        public func encode(to encoder: ABIFunctionEncoder) throws {
            try encoder.encode(address)
            try encoder.encode(index)
        }
    }
}
