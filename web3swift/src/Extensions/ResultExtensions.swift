//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Foundation

extension Result where Failure == JSONRPCError {
    init(catching body: () throws -> Success) {
        do {
            self = .success(try body())
        } catch {
            self = .failure(error as! JSONRPCError)
        }
    }

	func tryMap<NewSuccess>(_ transform: (Success) throws -> NewSuccess) -> Result<NewSuccess, JSONRPCError> {
		self.flatMap { value in
			Result<NewSuccess, JSONRPCError> { try transform(value) }
		}
	}
}
