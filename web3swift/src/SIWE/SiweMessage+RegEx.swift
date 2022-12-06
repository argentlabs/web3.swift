//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation

extension SiweMessage {
    /// Errors thrown while trying to parse a SIWE string message using RegEx
    enum RegExError: Swift.Error {
        /// Error thrown when no absolute matches were found in the message
        case noMatches
        /// Error thrown in case we couldn't create a JSON object from parsed values
        case invalidJson
    }

    /// Regular expressions were taken and adapted from SIWE maintainer's [main TypeScript repo](https://github.com/spruceid/siwe/blob/main/packages/siwe-parser/lib/regex.ts)
    ///
    /// Check [the docs web page](https://docs.login.xyz) for more info
    private enum RegEx {
        static let domain = "(?<\(CodingKeys.domain.rawValue)>([^?#]*)) wants you to sign in with your Ethereum account:"
        static let address = "\n(?<\(CodingKeys.address.rawValue)>0x[a-zA-Z0-9]{40})\n\n"
        static let statement = "((?<\(CodingKeys.statement.rawValue)>[^\n]+)\n)?"
        static let uri = "(([^:?#]+):)?(([^?#]*))?([^?#]*)(\\?([^#]*))?(#(.*))"
        static let uriLine = "\nURI: (?<\(CodingKeys.uri.rawValue)>\(uri)?)"
        static let version = "\nVersion: (?<\(CodingKeys.version.rawValue)>1)"
        static let chainId = "\nChain ID: (?<\(CodingKeys.chainId.rawValue)>[0-9]+)"
        static let nonce = "\nNonce: (?<\(CodingKeys.nonce.rawValue)>[a-zA-Z0-9]{8,})"
        static let dateTime = "([0-9]+)-(0[1-9]|1[012])-(0[1-9]|[12][0-9]|3[01])[Tt]([01][0-9]|2[0-3]):([0-5][0-9]):([0-5][0-9]|60)(\\.[0-9]+)?(([Zz])|([\\+|\\-]([01][0-9]|2[0-3]):[0-5][0-9]))"
        static let issuedAt = "\nIssued At: (?<\(CodingKeys.issuedAt.rawValue)>\(dateTime))"
        static let expirationTime = "(\nExpiration Time: (?<\(CodingKeys.expirationTime.rawValue)>\(dateTime)))?"
        static let notBefore = "(\nNot Before: (?<\(CodingKeys.notBefore.rawValue)>\(dateTime)))?"
        static let requestId = "(\nRequest ID: (?<\(CodingKeys.requestId.rawValue)>[-._~!$&'()*+,;=:@%a-zA-Z0-9]*))?"
        static let resources = "(\nResources:(?<\(CodingKeys.resources.rawValue)>(\n- \(uri)?)+))?"
        static let message = "^\(domain)\(address)\(statement)\(uriLine)\(version)\(chainId)\(nonce)\(issuedAt)\(expirationTime)\(notBefore)\(requestId)\(resources)$"
    }

    init(fromStringUsingRegEx string: String) throws {
        guard let regex = try? NSRegularExpression(pattern: RegEx.message, options: []) else {
            assertionFailure("Regular expression is invalid")
            throw RegExError.noMatches
        }
        let range = NSRange(string.startIndex ..< string.endIndex, in: string)
        guard let match = regex.firstMatch(in: string, options: [], range: range) else {
            throw RegExError.noMatches
        }

        var messageDict: [String: Any] = [:]
        for field in CodingKeys.allCases {
            let fieldNSRange = match.range(withName: field.rawValue)
            if fieldNSRange.location != NSNotFound,
               let fieldRange = Range(fieldNSRange, in: string) {
                let value = string[fieldRange]
                if field == .resources {
                    let resources = value.components(separatedBy: "\n- ").filter { !$0.isEmpty }
                    messageDict[field.rawValue] = resources
                } else {
                    messageDict[field.rawValue] = value
                }
            }
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(SiweMessage.dateFormatter)

        guard let jsonData = try? JSONSerialization.data(withJSONObject: messageDict, options: []) else {
            throw RegExError.invalidJson
        }

        self = try decoder.decode(SiweMessage.self, from: jsonData)
    }
}
