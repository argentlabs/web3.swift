//
//  EthereumContract.swift
//  web3swift
//
//  Created by Matt Marshall on 13/03/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation

public enum EthereumContractError: Error {
    case unknownFunction
    case unknownEvent
    case invalidData
    case invalidArgumentType
    case notImplemented
    case unknownError
    case invalidArgumentValue
    case noInputsOrOutputs
    case invalidSignature
}

protocol EthereumContractProtocol {
    var abi: [ABIEntry] { get }
    var address: String { get }
}

open class EthereumContract: EthereumContractProtocol {
    public var abi: [ABIEntry]
    public var address: String
    
    public init(abi: [ABIEntry], address: String) {
        self.abi = abi
        self.address = address
    }
    
    public init?(json: String, address: String) {
        guard let data = json.data(using: .utf8) else { return nil }
        guard let abi = try? JSONDecoder().decode([ABIEntry].self, from: data) else { return nil }
        self.abi = abi
        self.address = address
    }
    
    public init?(url: URL, address: String) {
        guard let data = try? Data(contentsOf: url) else { return nil }
        guard let abi = try? JSONDecoder().decode([ABIEntry].self, from: data) else { return nil }
        self.abi = abi
        self.address = address
    }
    
    public var functions: [String] {
        return self.abi.filter { $0.type == "function" }.map { $0.name ?? "" }
    }
    
    public var events: [String] {
        return self.abi.filter { $0.type == "event" }.map { $0.name ?? "" }
    }
    
    /// Generates the data for calling a function with a set of inputs.
    ///   - args: the input values
    public func data(function: String, args: [String]) throws -> String {
        guard let entry = self.abi.first(where: { $0.name == function && $0.type == "function"}) else {
            throw EthereumContractError.unknownFunction
        }
        guard let inputs = entry.inputs else { throw EthereumContractError.noInputsOrOutputs }
        let types = inputs.map { $0.type }
        
        let bytes = try ABIEncoder.encode(function: function, args: args, types: types)
        return String(hexFromBytes: bytes)
    }
    
    ///   - data: the data returned by the function as an hexadecimal string
    // Any is either a string or array
    public func decode(function: String, data: String) throws -> Any {
        guard let entry = self.abi.first(where: { $0.name == function && $0.type == "function"}) else {
            throw EthereumContractError.unknownFunction
        }
        guard let outputs = entry.outputs else { throw EthereumContractError.noInputsOrOutputs }
        let types = outputs.map { $0.type }
        return try ABIDecoder.decode(data: data, types: types)
    }
    
    /// Generates the topics associated to an event and a set of values for its arguments.
    /// There must be one value per argument exactly but the values can be null.
    public func topics(event: String, args: [String?]) throws -> [String?] {
        
        guard let entry = self.abi.first(where: { $0.name == event && $0.type == "event"}) else {
            throw EthereumContractError.unknownEvent
        }
        
        guard let inputs = entry.inputs else { throw EthereumContractError.noInputsOrOutputs }
        let types = inputs.map { $0.type }
        
        var topics = [String?]()
        
        let signature = try ABIEncoder.signature(name: event, types: types)
        topics.insert(String(hexFromBytes: signature), at: 0)
        
        for (index, arg) in args.enumerated() {
            let type = types[index]
            if let arg = arg {
                let result = try ABIEncoder.encodeArgument(type: type, arg: arg)
                topics.insert(String(hexFromBytes: result), at: index + 1)
            } else {
                topics.insert(nil, at: index + 1)
            }
        }
        
        return topics
    }
}
