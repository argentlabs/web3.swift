//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import BigInt
import Foundation

public class ERC165 {
    public let client: EthereumClientProtocol
    required public init(client: EthereumClientProtocol) {
        self.client = client
    }

    public func supportsInterface(contract: EthereumAddress, id: Data, completionHandler: @escaping(Result<Bool, Error>) -> Void) {
        let function = ERC165Functions.supportsInterface(contract: contract, interfaceId: id)

        function.call(withClient: client, responseType: ERC165Responses.supportsInterfaceResponse.self) { result in
            switch result {
            case .success(let data):
                completionHandler(.success(data.supported))
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }
}

// MARK: - Async/Await
extension ERC165 {
    public func supportsInterface(contract: EthereumAddress, id: Data) async throws -> Bool {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
            supportsInterface(contract: contract, id: id, completionHandler: continuation.resume)
        }
    }
}

public enum ERC165Functions {
    public static var interfaceId: Data {
        return "supportsInterface(bytes4)".web3.keccak256.web3.bytes4
    }

    struct supportsInterface: ABIFunction {
        public static let name = "supportsInterface"
        public let gasPrice: BigUInt?
        public let gasLimit: BigUInt?
        public var contract: EthereumAddress
        public let from: EthereumAddress?

        let interfaceId: Data

        public init(contract: EthereumAddress,
                    from: EthereumAddress? = nil,
                    interfaceId: Data,
                    gasPrice: BigUInt? = nil,
                    gasLimit: BigUInt? = nil) {
            self.contract = contract
            self.from = from
            self.interfaceId = interfaceId
            self.gasPrice = gasPrice
            self.gasLimit = gasLimit
        }

        public func encode(to encoder: ABIFunctionEncoder) throws {
            assert(interfaceId.count == 4, "Interface data should contain exactly 4 bytes")
            try encoder.encode(interfaceId, staticSize: 4)
        }
    }
}

public enum ERC165Responses {
    public struct supportsInterfaceResponse: ABIResponse {
        public static var types: [ABIType.Type] = [ Bool.self ]
        public let supported: Bool

        public init?(values: [ABIDecoder.DecodedValue]) throws {
            self.supported = try values[0].decoded()
        }
    }
}
