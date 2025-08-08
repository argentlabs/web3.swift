//
//  web3.swift
//  Copyright © Argent Labs Limited. All rights reserved.
//

import Foundation

extension Result where Failure == JSONRPCError {
    init(catching body: () throws -> Success) {
        do {
            self = try .success(body())
        } catch {
            self = .failure(error as! JSONRPCError)
        }
    }

    func tryMap<NewSuccess>(_ transform: (Success) throws -> NewSuccess) -> Result<NewSuccess, JSONRPCError> {
        flatMap { value in
            Result<NewSuccess, JSONRPCError> { try transform(value) }
        }
    }
}
