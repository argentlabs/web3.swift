//
//  File.swift
//  File
//
//  Created by Ronald Mannak on 8/24/21.
//

import Foundation

// FIXME: Indirect keyword needed because of couldNotDecodeResponse case that recursively wraps a Web3Error
public indirect enum Web3Error: Error {
    
    // Thrown by EthereumAccount
    case createAccountError
    case loadAccountError
    case signError
    
    // Thrown by EthereumSigner
    case emptyRawTransaction
    case unknownError
    
    // Thrown by EthereumKeyStorage
    case notFound
    case failedToSave
    case failedToLoad
    
    // Thrown by EthereumClient
    case tooManyResults
    case unexpectedReturnValue
    case noResult
    case decodeIssue
    case encodeIssue
    case noInputData
    
    // Thrown by JSONRPC
    case executionError(JSONRPCErrorResult)
    case requestRejected(Data)
    case encodingError
    case decodingError
    
    // Thrown by ABI
    case invalidSignature
    case invalidType
    case invalidValue
    case incorrectParameterCount
    case notCurrentlySupported
    
    // Thrown by EthereumNamingService
    case noNetwork
    case noResolver
    case ensUnknown
    case invalidInput
    
    // Thrown by MultiCall
    case contractUnavailable
    
    // Thrown by Call
    case contractFailure
    case couldNotDecodeResponse(Web3Error?)
}

extension Web3Error: Equatable {
    
    public static func == (lhs: Web3Error, rhs: Web3Error) -> Bool {
        switch (lhs, rhs) {
        case (.createAccountError, .createAccountError),
            (.loadAccountError, .loadAccountError),
            (.signError, .signError),
            (.emptyRawTransaction, .emptyRawTransaction),
            (.unknownError, .unknownError),
            (.notFound, .notFound),
            (.failedToSave, .failedToSave),
            (failedToLoad, .failedToLoad),
            (.tooManyResults, .tooManyResults),
            (.unexpectedReturnValue, .unexpectedReturnValue),
            (.noResult, .noResult),
            (.decodeIssue, .decodeIssue),
            (.encodeIssue, .encodeIssue),
            (.noInputData, .noInputData),
            (.encodingError, .encodingError),
            (.decodingError, .decodingError),
            (.invalidSignature, .invalidSignature),
            (.invalidType, .invalidType),
            (.invalidValue, .invalidValue),
            (.incorrectParameterCount, .incorrectParameterCount),
            (.notCurrentlySupported, .notCurrentlySupported),
            (.noNetwork, .noNetwork),
            (.noResolver, .noResolver),
            (.ensUnknown, .ensUnknown),
            (.invalidInput, .invalidInput),
            (.contractUnavailable, .contractUnavailable),
            (.contractFailure, .contractFailure):
            return true
        case (.executionError(let lhsCode), .executionError(let rhsCode)):
            return lhsCode == rhsCode
        case (.requestRejected(let lhsData), .requestRejected(let rhsData)):
            return lhsData == rhsData
        case (.couldNotDecodeResponse(let lhsError), .couldNotDecodeResponse(let rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }
}
