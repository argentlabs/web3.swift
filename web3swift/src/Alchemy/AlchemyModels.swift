//
//  File.swift
//  File
//
//  Created by Ronald Mannak on 8/27/21.
//

import Foundation
import BigInt

public struct AlchemyTokenBalances: Equatable, Decodable {    
    let address: EthereumAddress
    let tokenBalances: [AlchemyTokenBalance]
}

public struct AlchemyTokenBalance {
    let contractAddress: EthereumAddress
    let tokenBalance: BigUInt?
    let error: String? // Error?
}

extension AlchemyTokenBalance: Decodable {
    
    enum CodingKeys : String, CodingKey {
        case contractAddress
        case tokenBalance
        case error
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.contractAddress = try container.decode(EthereumAddress.self, forKey: .contractAddress)

        let decodeHexUInt = { (key: CodingKeys) -> BigUInt? in
            return (try? container.decode(String.self, forKey: key)).flatMap { BigUInt(hex: $0)}
        }
        
        self.tokenBalance = decodeHexUInt(.tokenBalance)
//        if let tokenBalance = decodeHexUInt(.tokenBalance) {
//            self.tokenBalance = tokenBalance
//        } else {
//            self.tokenBalance = BigUInt(0)
//        }
        self.error = try? container.decode(String.self, forKey: .error)
    }
}

extension AlchemyTokenBalance: Equatable {
    public static func == (lhs: AlchemyTokenBalance, rhs: AlchemyTokenBalance) -> Bool {
        return lhs.contractAddress == rhs.contractAddress
    }
}




// see ethereumTransactionReceipt

/*
address: The address for which token balances were checked.
tokenBalances: An array of token balance objects. Each object contains:
contractAddress: The address of the contract.
tokenBalance: The balance of the contract, as a string representing a base-10 number.
error: An error string. One of this or tokenBalance will be null.

"{\"jsonrpc\": \"2.0\", \"id\": 1, \"result\":
{\"address\": \"0xb739d0895772dbb71a89a3754a160269068f0d45\",
    \"tokenBalances\":
    [{\"contractAddress\": \"0xdac17f958d2ee523a2206206994597c13d831ec7\", \"tokenBalance\": \"0x0000000000000000000000000000000000000000000000000000000000000000\", \"error\": null}, {\"contractAddress\": \"0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48\", \"tokenBalance\": \"0x0000000000000000000000000000000000000000000000000000000000000000\", \"error\": null}, {\"contractAddress\": \"0xf5d669627376ebd411e34b98f19c868c8aba5ada\", \"tokenBalance\": \"0x0000000000000000000000000000000000000000000000000000000000000000\", \"error\": null}, {\"contractAddress\": \"0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2\", \"tokenBalance\": \"0x0000000000000000000000000000000000000000000000000000000000000000\", \"error\": null}, {\"contractAddress\": \"0x514910771af9ca656af840dff83e8264ecf986ca\", \"tokenBalance\": \"0x0000000000000000000000000000000000000000000000000000000000000000\", \"error\": null}, {\"contractAddress\": \"0xa2120b9e674d3fc3875f415a7df52e382f141225\", \"tokenBalance\": \"0x0000000000000000000000000000000000000000000000000000000000000000\", \"error\": null}, {\"contractAddress\": \"0xae12c5930881c53715b369cec7606b70d8eb229f\", \"tokenBalance\": \"0x0000000000000000000000000000000000000000000000000000000000000000\", \"error\": null}, {\"contractAddress\": \"0xbb0e17ef65f82ab018d8edd776e8dd940327b28b\", \"tokenBalance\": \"0x0000000000000000000000000000000000000000000000000000000000000000\", \"error\": null}, {\"contractAddress\": \"0x3845badade8e6dff049820680d1f14bd3903a5d0\", \"tokenBalance\": \"0x0000000000000000000000000000000000000000000000000000000000000000\", \"error\": null}, {\"contractAddress\": \"0xdf574c24545e5ffecb9a659c229253d4111d87e1\", \"tokenBalance\": \"0x0000000000000000000000000000000000000000000000000000000000000000\", \"error\": null}, {\"contractAddress\":
*/
