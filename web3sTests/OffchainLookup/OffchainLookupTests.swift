//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import BigInt
import XCTest
@testable import web3

struct DummyOffchainENSResolve: ABIFunction {
    static var name: String = "resolver"
    var gasPrice: BigUInt?
    var gasLimit: BigUInt?

    var contract: EthereumAddress = "0x03669aC51fCf68302440d2e8b63F91F901DDE212"

    var from: EthereumAddress?
    var node: Data

    func encode(to encoder: ABIFunctionEncoder) throws {
        try encoder.encode(node, staticSize: 32)
    }
}

// https://github.com/ethers-io/ethers.js/blob/master/packages/tests/src.ts/test-providers.ts
enum EthersTestContract {
    struct TestGet: ABIFunction {
        static var name: String = "testGet"
        var gasPrice: BigUInt?
        var gasLimit: BigUInt?

        var contract: EthereumAddress = "0x6C5ed35574a9b4d163f75bBf0595F7540D8FCc2d"

        var from: EthereumAddress?
        var data: Data

        func encode(to encoder: ABIFunctionEncoder) throws {
            try encoder.encode(data)
        }
    }

    struct TestGetFail: ABIFunction {
        static var name: String = "testGetFail"
        var gasPrice: BigUInt?
        var gasLimit: BigUInt?

        var contract: EthereumAddress = "0x6C5ed35574a9b4d163f75bBf0595F7540D8FCc2d"

        var from: EthereumAddress?
        var data: Data

        func encode(to encoder: ABIFunctionEncoder) throws {
            try encoder.encode(data)
        }
    }

    struct TestGetSenderFail: ABIFunction {
        static var name: String = "testGetSenderFail"
        var gasPrice: BigUInt?
        var gasLimit: BigUInt?

        var contract: EthereumAddress = "0x6C5ed35574a9b4d163f75bBf0595F7540D8FCc2d"

        var from: EthereumAddress?
        var data: Data

        func encode(to encoder: ABIFunctionEncoder) throws {
            try encoder.encode(data)
        }
    }

    struct TestGetMissing: ABIFunction {
        static var name: String = "testGetMissing"
        var gasPrice: BigUInt?
        var gasLimit: BigUInt?

        var contract: EthereumAddress = "0x6C5ed35574a9b4d163f75bBf0595F7540D8FCc2d"

        var from: EthereumAddress?
        var data: Data

        func encode(to encoder: ABIFunctionEncoder) throws {
            try encoder.encode(data)
        }
    }

    struct TestGetFallback: ABIFunction {
        static var name: String = "testGetFallback"
        var gasPrice: BigUInt?
        var gasLimit: BigUInt?

        var contract: EthereumAddress = "0x6C5ed35574a9b4d163f75bBf0595F7540D8FCc2d"

        var from: EthereumAddress?
        var data: Data

        func encode(to encoder: ABIFunctionEncoder) throws {
            try encoder.encode(data)
        }
    }

    struct TestPost: ABIFunction {
        static var name: String = "testPost"
        var gasPrice: BigUInt?
        var gasLimit: BigUInt?

        var contract: EthereumAddress = "0x6C5ed35574a9b4d163f75bBf0595F7540D8FCc2d"

        var from: EthereumAddress?
        var data: Data

        func encode(to encoder: ABIFunctionEncoder) throws {
            try encoder.encode(data)
        }
    }

    struct BytesResponse: ABIResponse {
        static var types: [ABIType.Type] {
            [Data32.self]
        }

        let data: Data

        init?(values: [ABIDecoder.DecodedValue]) throws {
            self.data = try values[0].decoded()
        }
    }
}

extension EthereumClientError {
    var executionError: JSONRPCErrorDetail? {
        switch self {
        case .executionError(let detail):
            return detail
        default:
            return nil
        }
    }
}

class OffchainLookupTests: XCTestCase {
    var client: EthereumClientProtocol!
    var account: EthereumAccount!
    var offchainLookup = OffchainLookup(address: .zero, urls: [], callData: Data(), callbackFunction: Data(), extraData: Data())
    
    override func setUp() {
        super.setUp()
        client = EthereumHttpClient(url: URL(string: TestConfig.clientUrl)!, network: TestConfig.network)
        account = try? EthereumAccount(keyStorage: TestEthereumKeyStorage(privateKey: TestConfig.privateKey))
    }

    func test_GivenFunctionWithOffchainLookupError_ThenDecodesLookupParamsCorrectly() async throws {
        let function =  DummyOffchainENSResolve(
            node: EthereumNameService.nameHash(name: "hello.argent.xyz").web3.hexData!
        )

        let tx = try! function.transaction()

        do {
            _ = try await client.eth_call(tx, resolution: .noOffchain(failOnExecutionError: true), block: .Latest)
            XCTFail("Expecting error, not return value")
        } catch let error {
            let error = (error as? EthereumClientError)?.executionError
            let decoded = try? error?.decode(error: offchainLookup)

            XCTAssertEqual(error?.code, JSONRPCErrorCode.contractExecution)
            XCTAssertEqual(try? decoded?[0].decoded(), EthereumAddress("0x03669aC51fCf68302440d2e8b63F91F901DDE212"))
            XCTAssertEqual(try? decoded?[1].decodedArray(), ["https://argent.xyz"])
            XCTAssertEqual(try? decoded?[2].decoded(), Data(hex: "0x35b8485202b076a4e2d0173bf3d7e69546db3eb92389469473b2680c3cdb4427cafbcf2a")!)
            XCTAssertEqual(try? decoded?[3].decoded(), Data(hex: "0xd2479f3e")!)
            XCTAssertEqual(try? decoded?[4].decoded(), Data())
        }
    }

    // TODO [Tests] Disabled for now until we reimplement on our side (ethers.js tests setup using goerli)
//    func test_GivenTestFunction_WhenLookupCorrect_ThenDecodesRetrievesValue() async throws {
//        let function =  EthersTestContract.TestGet(data: "0x1234".web3.hexData!)
//
//        do {
//            let response = try await function.call(
//                withClient: client,
//                responseType: EthersTestContract.BytesResponse.self,
//                resolution: .offchainAllowed(maxRedirects: 5)
//            )
//
//            XCTAssertEqual(
//                response.data.web3.hexString,
//                expectedResponse(
//                    sender: function.contract,
//                    data: "0x1234".web3.hexData!)
//            )
//        } catch let error {
//            XCTFail("Error \(error)")
//        }
//    }
//
//    func test_GivenTestFunction_WhenLookupDisabled_ThenFailsWithExecutionError() async throws {
//        let function =  EthersTestContract.TestGet(data: "0x1234".web3.hexData!)
//
//        do {
//            _ = try await function.call(
//                withClient: client,
//                responseType: EthersTestContract.BytesResponse.self,
//                resolution: .noOffchain(failOnExecutionError: true)
//            )
//            XCTFail("Expecting error")
//        } catch let error {
//            let error = (error as? EthereumClientError)?.executionError
//            XCTAssertEqual(error?.code, 3)
//        }
//    }
//
//    func test_GivenTestFunction_WhenGatewayFails_ThenFailsCall() async throws {
//        let function =  EthersTestContract.TestGetFail(data: "0x1234".web3.hexData!)
//
//        do {
//            _ = try await function.call(
//                withClient: client,
//                responseType: EthersTestContract.BytesResponse.self,
//                resolution: .offchainAllowed(maxRedirects: 5)
//            )
//            XCTFail("Expecting error")
//        } catch let error {
//            XCTAssertEqual(error as? EthereumClientError, EthereumClientError.noResultFound)
//        }
//    }
//
//    func test_GivenTestFunction_WhenSendersDoNotMatch_ThenFailsCall() async throws {
//        let function =  EthersTestContract.TestGetSenderFail(data: "0x1234".web3.hexData!)
//
//        do {
//            _ = try await function.call(
//                withClient: client,
//                responseType: EthersTestContract.BytesResponse.self,
//                resolution: .offchainAllowed(maxRedirects: 5)
//            )
//            XCTFail("Expecting error")
//        } catch _ {
//        }
//    }
//
//    func test_GivenTestFunction_WhenGatewayFailsWith4xx_ThenFailsCall() async throws {
//        let function =  EthersTestContract.TestGetMissing(data: "0x1234".web3.hexData!)
//
//        do {
//            _ = try await function.call(
//                withClient: client,
//                responseType: EthersTestContract.BytesResponse.self,
//                resolution: .offchainAllowed(maxRedirects: 5)
//            )
//            XCTFail("Expecting error")
//        } catch let error {
//            XCTAssertEqual(error as? EthereumClientError, EthereumClientError.noResultFound)
//        }
//    }
//
//    func test_GivenTestFunction_WhenLookupCorrectWithFallback_ThenDecodesRetrievesValue() async throws {
//        let function =  EthersTestContract.TestGetFallback(data: "0x1234".web3.hexData!)
//
//        do {
//            let response = try await function.call(
//                withClient: client,
//                responseType: EthersTestContract.BytesResponse.self,
//                resolution: .offchainAllowed(maxRedirects: 5)
//            )
//
//            XCTAssertEqual(
//                response.data.web3.hexString,
//                expectedResponse(
//                    sender: function.contract,
//                    data: "0x1234".web3.hexData!)
//            )
//        } catch let error {
//            XCTFail("Error \(error)")
//        }
//    }
//
//    func test_GivenTestFunction_WhenLookupCorrectWithFallbackAndNoRedirectsLeft_ThenFails() async throws {
//        let function =  EthersTestContract.TestGetFallback(data: "0x1234".web3.hexData!)
//
//        do {
//            _ = try await function.call(
//                withClient: client,
//                responseType: EthersTestContract.BytesResponse.self,
//                resolution: .offchainAllowed(maxRedirects: 0)
//            )
//
//            XCTFail("Expecting error")
//        } catch let error {
//            XCTAssertEqual(error as? EthereumClientError, EthereumClientError.noResultFound)
//        }
//    }
//
//    func test_GivenTestFunction_WhenLookupCorrectWithPOSTData_ThenDecodesRetrievesValue() async throws {
//        let function =  EthersTestContract.TestPost(data: "0x1234".web3.hexData!)
//
//        do {
//            let response = try await function.call(
//                withClient: client,
//                responseType: EthersTestContract.BytesResponse.self,
//                resolution: .offchainAllowed(maxRedirects: 5)
//            )
//
//            XCTAssertEqual(
//                response.data.web3.hexString,
//                expectedResponse(
//                    sender: function.contract,
//                    data: "0x1234".web3.hexData!)
//            )
//        } catch let error {
//            XCTFail("Error \(error)")
//        }
//    }
}

// Expected hash of result, which is the same verification done in ethers contract
private func expectedResponse(
    sender: EthereumAddress,
    data: Data
) -> String {
    let senderData = sender.asData()!
    return Data([
        [UInt8(senderData.count)],
        senderData.web3.bytes,
        [UInt8(data.count)],
        data.web3.bytes
        ]
        .flatMap { $0 }
    ).web3.keccak256.web3.hexString
}

class OffchainLookupWebSocketTests: OffchainLookupTests {
    override func setUp() {
        super.setUp()
        client = EthereumWebSocketClient(url: URL(string: TestConfig.wssUrl)!, configuration: TestConfig.webSocketConfig, network: TestConfig.network)
    }
}
