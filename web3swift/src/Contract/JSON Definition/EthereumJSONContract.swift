//
//  EthereumJSONContract.swift
//  web3swift
//
//  Created by Matt Marshall on 13/03/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation

public enum EthereumJSONContractError: Error {
    case unknownFunction
    case unknownEvent
}

protocol EthereumJSONContractProtocol {
    var abi: [ABIJSONEntry] { get }
    var address: EthereumAddress { get }
}

open class EthereumJSONContract: EthereumJSONContractProtocol {
    public var abi: [ABIJSONEntry]
    public var address: EthereumAddress
    
    public init(abi: [ABIJSONEntry], address: EthereumAddress) {
        self.abi = abi
        self.address = address
    }
    
    public init?(json: String, address: EthereumAddress) {
        guard let data = json.data(using: .utf8) else { return nil }
        guard let abi = try? JSONDecoder().decode([ABIJSONEntry].self, from: data) else { return nil }
        self.abi = abi
        self.address = address
    }
    
    public init?(url: URL, address: EthereumAddress) {
        guard let data = try? Data(contentsOf: url) else { return nil }
        guard let abi = try? JSONDecoder().decode([ABIJSONEntry].self, from: data) else { return nil }
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
    public func data(function: String, args: [String]) throws -> Data {
        guard let entry = self.abi.first(where: { $0.name == function && $0.type == "function"}) else {
            throw EthereumJSONContractError.unknownFunction
        }
        guard let inputs = entry.inputs else { throw ABIError.incorrectParameterCount }
        let types = inputs.map { $0.type }
        
        let bytes = try ABIEncoder.encode(function: function, args: args, types: types)
        return Data( bytes)
    }
    
    /// Generates the transaction for calling a function with a set of inputs.
    ///   - args: the input values
    public func transaction(function: String, args: [String]) throws -> EthereumTransaction {
        let data = try self.data(function: function, args: args)
        return EthereumTransaction(to: address, data: data)
    }
    
    ///   - data: the data returned by the function as an hexadecimal string
    // Any is either a string or array
    public func decode(function: String, data: String) throws -> Any {
        guard let entry = self.abi.first(where: { $0.name == function && $0.type == "function"}) else {
            throw EthereumJSONContractError.unknownFunction
        }
        guard let outputs = entry.outputs else { throw ABIError.incorrectParameterCount }
        let types = outputs.map { $0.type }
        return try ABIDecoder.decodeData(data, types: types)
    }
    
    /// Generates the topics associated to an event and a set of values for its arguments.
    /// There must be one value per argument exactly but the values can be null.
    public func topics(event: String, args: [String?]) throws -> [String?] {
        
        guard let entry = self.abi.first(where: { $0.name == event && $0.type == "event"}) else {
            throw EthereumJSONContractError.unknownEvent
        }
        
        guard let inputs = entry.inputs else { throw ABIError.incorrectParameterCount }
        let types = inputs.map { $0.type }
        
        var topics = [String?]()
        
        let signature = try ABIEncoder.signature(name: event, types: types)
        topics.insert(String(hexFromBytes: signature), at: 0)
        
        for (index, arg) in args.enumerated() {
            if let arg = arg {
                guard let type = ABIRawType(rawValue: types[index]) else {
                    throw ABIError.invalidType
                }
                let result = try ABIEncoder.encode(arg, forType: type)
                topics.insert(String(hexFromBytes: result), at: index + 1)
            } else {
                topics.insert(nil, at: index + 1)
            }
        }
        
        return topics
    }
}
