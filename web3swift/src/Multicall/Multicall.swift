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

    public func aggregate(calls: [Call],
                          completionHandler: @escaping (Result<MulticallResponse, MulticallError>) -> Void) {
        guard let network = client.network,
              let contract = Contract.registryAddress(for: network)
        else { return completionHandler(.failure(MulticallError.contractUnavailable)) }

        let function = Contract.Functions.aggregate(contract: contract, calls: calls)

        function.call(withClient: client, responseType: Response.self) { result in
            switch result {
            case .success(let data):
                guard calls.count == data.outputs.count
                else { fatalError("Outputs do not match the number of calls done") }

                zip(calls, data.outputs)
                    .forEach { call, output in
                        try? call.handler?(output)
                    }
                completionHandler(.success(data))
            case .failure(let error):
                completionHandler(.failure(MulticallError.executionFailed(error)))
            }
        }
    }
}

// MARK: - Async/Await
extension Multicall {
    public func aggregate(calls: [Call]) async -> Result<MulticallResponse, MulticallError> {
        return await withCheckedContinuation { (continuation: CheckedContinuation<Result<MulticallResponse, MulticallError>, Never>) in
            aggregate(calls: calls, completionHandler: continuation.resume)
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
                guard result != Self.multicallFailedError
                else { return .failure(.contractFailure) }

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
                        do {
                            if let response = try Response(data: $0) {
                                return .success(response.value)
                            } else {
                                return .failure(.couldNotDecodeResponse(nil))
                            }
                        } catch let error {
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
