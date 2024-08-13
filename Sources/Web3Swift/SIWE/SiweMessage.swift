//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation

/// Sign-in with Ethereum (SIWE) base message struct
///
/// For more information on SIWE check out https://docs.login.xyz
public struct SiweMessage: Hashable {
    /// RFC 4501 dns authority that is requesting the signing.
    public var domain: String

    /// Ethereum address performing the signing conformant to capitalization encoded checksum specified in EIP-55 where applicable.
    public var address: String

    /// Human-readable ASCII assertion that the user will sign, and it must not contain `\n`.
    public var statement: String?

    /// RFC 3986 URI referring to the resource that is the subject of the signing (as in the __subject__ of a claim).
    public var uri: URL

    /// Current version of the message.
    public var version: String

    /// EIP-155 Chain ID to which the session is bound, and the network where Contract Accounts must be resolved.
    public var chainId: Int

    /// Randomized token used to prevent replay attacks, at least 8 alphanumeric characters.
    public var nonce: String

    /// Datetime which the message was issued at/
    public var issuedAt: Date

    /// Datetime which, if present, indicates when the signed message is no longer valid.
    public var expirationTime: Date?

    /// Datetime which, if present, indicates when the signed message will become valid.
    public var notBefore: Date?

    /// System-specific identifier that may be used to uniquely refer to the sign-in request.
    public var requestId: String?

    /// List of information or references to information the user wishes to have resolved as part of authentication by the relying party.
    /// They are expressed as RFC 3986 URIs separated by `\n- `.
    public var resources: [URL]?

    public init(
        domain: String,
        address: String,
        statement: String?,
        uri: URL,
        version: String,
        chainId: Int,
        nonce: String,
        issuedAt: Date,
        expirationTime: Date?,
        notBefore: Date?,
        requestId: String?,
        resources: [URL]?
    ) throws {
        self.domain = domain
        self.address = address
        self.statement = statement
        self.uri = uri
        self.version = version
        self.chainId = chainId
        self.nonce = nonce
        self.issuedAt = issuedAt
        self.expirationTime = expirationTime
        self.notBefore = notBefore
        self.requestId = requestId
        self.resources = resources

        try validate()
    }
}
