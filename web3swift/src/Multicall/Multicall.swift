//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import BigInt
import Foundation

public typealias MulticallResponse = Multicall.Response

public struct Multicall {
    private let client: EthereumClientProtocol

    public init(client: EthereumClientProtocol) {
        self.client = client
    }

    public func aggregate(calls: [Call]) async throws -> MulticallResponse {
        guard let network = client.network, let contract = Contract.registryAddress(for: network) else {
            throw MulticallError.contractUnavailable
        }

        let function = Contract.Functions.aggregate(contract: contract, calls: calls)

        do {
            let data = try await function.call(withClient: client, responseType: Response.self)
            guard calls.count == data.outputs.count else {
                fatalError("Outputs do not match the number of calls done")
            }

            zip(calls, data.outputs)
                .forEach { call, output in
                    try? call.handler?(output)
                }
            return data
        } catch {
            throw MulticallError.executionFailed(error)
        }
    }

    public func tryAggregate(requireSuccess: Bool, calls: [Call]) async throws -> Multicall.Multicall2Response {
        let function = Contract.Functions.tryAggregate(contract: Contract.multicall2Address, requireSuccess: requireSuccess, calls: calls)

        do {
            let data = try await function.call(withClient: client, responseType: Multicall2Response.self)
            zip(calls, data.outputs)
                .forEach { call, output in
                    try? call.handler?(output)
                }
            return data
        } catch {
            throw MulticallError.executionFailed(error)
        }
    }
}

extension Multicall {
    public func aggregate(calls: [Call], completionHandler: @escaping (Result<MulticallResponse, MulticallError>) -> Void) {
        Task {
            do {
                let res = try await aggregate(calls: calls)
                completionHandler(.success(res))
            } catch let error as MulticallError {
                completionHandler(.failure(error))
            }
        }
    }

    public func tryAggregate(requireSuccess: Bool, calls: [Call], completionHandler: @escaping (Result<Multicall2Response, MulticallError>) -> Void) {
        Task {
            do {
                let res = try await tryAggregate(requireSuccess: requireSuccess, calls: calls)
                completionHandler(.success(res))
            } catch let error as MulticallError {
                completionHandler(.failure(error))
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
        case contractFailure
        case couldNotDecodeResponse(Error?)
    }

    public typealias Output = Result<String, CallError>

    public struct Response: ABIResponse {
        static let multicallFailedError = "MULTICALL_FAIL".web3.keccak256.web3.hexString

        public static var types: [ABIType.Type] = [BigUInt.self, ABIArray<String>.self]

        public let block: BigUInt
        public let outputs: [Output]

        public init?(values: [ABIDecoder.DecodedValue]) throws {
            self.block = try values[0].decoded()
            self.outputs = values[1].entry.map { result in
                guard result != Self.multicallFailedError else {
                    return .failure(.contractFailure)
                }

                return .success(result)
            }
        }
    }

    public struct Multicall2Result: ABITuple {
        public static var types: [ABIType.Type] = [Bool.self, String.self]
        public var encodableValues: [ABIType] { [success, returnData] }

        public let success: Bool
        public let returnData: String

        public init?(values: [ABIDecoder.DecodedValue]) throws {
            self.success = try values[0].decoded()
            self.returnData = values[1].entry[0]
        }

        public func encode(to encoder: ABIFunctionEncoder) throws {
            try encoder.encode(success)
            try encoder.encode(returnData)
        }
    }

    public struct Multicall2Response: ABIResponse {
        static let multicallFailedError = "MULTICALL_FAIL".web3.keccak256.web3.hexString
        public static var types: [ABIType.Type] = [ABIArray<Multicall2Result>.self]
        public let outputs: [Output]

        public init?(values: [ABIDecoder.DecodedValue]) throws {
            let results: [Multicall2Result] = try values[0].decodedTupleArray()
            self.outputs = results.map { result in
                guard result.returnData != Self.multicallFailedError else {
                    return .failure(.contractFailure)
                }
                return .success(result.returnData)
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
                        do {
                            if let response = try Response(data: $0) {
                                return .success(response.value)
                            } else {
                                return .failure(.couldNotDecodeResponse(nil))
                            }
                        } catch {
                            return .failure(.couldNotDecodeResponse(error))
                        }
                    }
                )
            }))
        }
    }
}

public protocol MulticallDecodableResponse {
    associatedtype Value

    var value: Value { get }

    init?(data: String) throws
}
