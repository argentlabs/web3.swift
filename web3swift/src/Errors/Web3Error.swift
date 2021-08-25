//
//  File.swift
//  File
//
//  Created by Ronald Mannak on 8/24/21.
//

import Foundation

enum Web3Error: Error {
    
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
//    case executionError Instead use executionError(JSONRPCErrorResult)
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
//    case unknownError
//    case noResult
    
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
//    case decodeIssue
    
    // Thrown by MultiCall
    case contractUnavailable
    case executionFailed(Error?)
    
    // Thrown by Call
    case contractFailure
    case couldNotDecodeResponse(Error?)
}

/*
public enum EthereumAccountError: Error {
    case createAccountError
    case loadAccountError
    case signError
}

enum EthereumSignerError: Error {
    case emptyRawTransaction
    case unknownError
}

public enum EthereumKeyStorageError: Error {
    case notFound
    case failedToSave
    case failedToLoad
}

public enum EthereumClientError: Error {
    case tooManyResults
    case executionError
    case unexpectedReturnValue
    case noResult
    case decodeIssue
    case encodeIssue
    case noInputData
}

public enum JSONRPCError: Error {
    case executionError(JSONRPCErrorResult)
    case requestRejected(Data)
    case encodingError
    case decodingError
    case unknownError
    case noResult

    var isExecutionError: Bool {
        switch self {
        case .executionError:
            return true
        default:
            return false
        }
    }
}

public enum ABIError: Error {
    case invalidSignature
    case invalidType
    case invalidValue
    case incorrectParameterCount
    case notCurrentlySupported
}
public enum EthereumNameServiceError: Error, Equatable {
    case noNetwork
    case noResolver
    case ensUnknown
    case invalidInput
    case decodeIssue
}

public enum MulticallError: Error {
    case contractUnavailable
    case executionFailed(Error?)
}

public enum CallError: Error {
    case contractFailure
    case couldNotDecodeResponse(Error?)
}
*/
