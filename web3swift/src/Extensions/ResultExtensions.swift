//
//  ResultExtensions.swift
//  web3swift
//
//  Created by Dionisis Karatzas on 2/6/22.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation

extension Result where Failure == EthereumClientError {
    init(catching body: () throws -> Success) {
        do {
            self = .success(try body())
        } catch {
            self = .failure(error as! EthereumClientError)
        }
    }

	func tryMap<NewSuccess>(_ transform: (Success) throws -> NewSuccess) -> Result<NewSuccess, EthereumClientError> {
		self.flatMap { value in
			Result<NewSuccess, EthereumClientError> { try transform(value) }
		}
	}
}
