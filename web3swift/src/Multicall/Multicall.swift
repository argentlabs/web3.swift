//
//  Multicall.swift
//  web3swift
//
//  Created by David Rodrigues on 28/10/2020.
//  Copyright © 2020 Argent Labs Limited. All rights reserved.
//

import Foundation
import BigInt

public typealias MulticallResponse = Multicall.Response

public struct Multicall {
    private let client: EthereumClient

    public init(client: EthereumClient) {
        self.client = client
    }

    public func aggregate(
        calls: [Call],
        completion: @escaping (Result<MulticallResponse, Error>) -> Void
    ) {
        guard
            let network = client.network,
            let contract = Contract.registryAddress(for: network)
        else { return completion(.failure(MulticallError.contractUnavailable)) }

        let function = Contract.Functions.aggregate(contract: contract, calls: calls)

        function.call(withClient: client, responseType: Response.self) { (error, response) in
            if let response = response {
                guard calls.count == response.outputs.count
                    else { fatalError("Outputs do not match the number of calls done") }

                zip(calls, response.outputs)
                    .forEach { call, output in
                        try? call.handler?(output)
                    }

                completion(.success(response))
            } else {
                completion(.failure(MulticallError.executionFailed(error)))
            }
        }
    }
}

extension Multicall {

    public enum MulticallError: Error {
        case contractUnavailable
        case executionFailed(Error?)
    }

    public enum CallError: Error {
        case failed
    }

    public typealias Output = Result<String, CallError>

    public struct Response: ABIResponse {
        static let multicallFailedError = "MULTICALL_FAIL".web3.keccak256.web3.hexString

        public static var types: [ABIType.Type] = [BigUInt.self, ABIArray<String>.self]

        public let block: BigUInt
        public let outputs: [Output]

        public init?(values: [ABIDecoder.DecodedValue]) throws {
            block = try values[0].decoded()
            outputs = values[1].entry.map { result in
                guard result != Self.multicallFailedError
                    else { return .failure(.failed) }

                return .success(result)
            }
        }
    }

    public struct Call: ABITuple {
        public static var types: [ABIType.Type] = [EthereumAddress.self, Data.self]
        public var encodableValues: [ABIType] { [target, encodedFunction] }

        public let target: EthereumAddress
        public let encodedFunction: Data
        public let handler: ((Output) throws -> Void)?

        public init<Function: ABIFunction>(function: Function, handler: ((Output) throws -> Void)? = nil) throws {
            self.target = function.contract
            self.encodedFunction = try {
                let encoder = ABIFunctionEncoder(Function.name)
                try function.encode(to: encoder)
                return try encoder.encoded()
            }()
            self.handler = handler
        }

        public init?(values: [ABIDecoder.DecodedValue]) throws {
            self.target = try values[0].decoded()
            self.encodedFunction = try values[1].decoded()
            self.handler = nil
        }

        public func encode(to encoder: ABIFunctionEncoder) throws {
            try encoder.encode(target)
            try encoder.encode(encodedFunction)
        }
    }

    public struct Aggregator {
        public private(set) var calls: [Call] = []

        public init() {}

        public mutating func append<Function: ABIFunction>(_ f: Function) throws {
            try calls.append(.init(function: f))
        }

        public mutating func append<Function: ABIFunction>(_ f: Function, handler: @escaping (Output) throws -> Void) throws {
            try calls.append(.init(function: f, handler: handler))
        }

        public mutating func append<Function: ABIFunction, Response: MulticallDecodableResponse>(
            function f: Function,
            response: Response.Type,
            handler: @escaping (Result<Response.Value, CallError>) throws -> Void
        ) throws {
            try calls.append(.init(function: f, handler: { output in
                try handler(
                    output.flatMap {
                        if let response = try? Response(data: $0) {
                            return .success(response.value)
                        } else {
                            return .failure(.failed)
                        }
                    }
                )
            }))
        }
    }
}

public protocol MulticallDecodableResponse: ABIResponse {
    associatedtype Value

    var value: Value { get }

    init?(data: String) throws
}
