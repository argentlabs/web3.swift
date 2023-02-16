//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import BigInt
import XCTest
@testable import web3

class ABIFunctionEncoderTests: XCTestCase {
    var encoder: ABIFunctionEncoder!

    override func setUp() {
        encoder = ABIFunctionEncoder("test")
    }

    func testGivenEmptyString_ThenEncodesCorrectly() {
        XCTAssertNoThrow(try encoder.encode(""))
        let encoded = try! encoder.encoded()
        XCTAssertEqual(String(hexFromBytes: encoded.web3.bytes), "0xf9fbd554000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000")
    }

    func testGivenNonEmptyString_ThenEncodesCorrectly() {
        XCTAssertNoThrow(try encoder.encode("hi"))
        let encoded = try! encoder.encoded()
        XCTAssertEqual(String(hexFromBytes: encoded.web3.bytes), "0xf9fbd554000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000026869000000000000000000000000000000000000000000000000000000000000")
    }

    func testGivenUInt_WhenNoExplicitSize_ThenEncodesAs256() {
        XCTAssertNoThrow(try encoder.encode(BigUInt(100)))
        let encoded = try! encoder.encoded()
        XCTAssertEqual(String(hexFromBytes: encoded.web3.bytes), "0x29e99f070000000000000000000000000000000000000000000000000000000000000064")
    }

    func testGivenUInt_WhenExplicitSize256_ThenEncodesAs256() {
        XCTAssertNoThrow(try encoder.encode(BigUInt(100), staticSize: 256))
        let encoded = try! encoder.encoded()
        XCTAssertEqual(String(hexFromBytes: encoded.web3.bytes), "0x29e99f070000000000000000000000000000000000000000000000000000000000000064")
    }

    func testGivenUInt_WhenValidExplicitSize100_ThenEncodesAs100() {
        XCTAssertNoThrow(try encoder.encode(BigUInt(100), staticSize: 100))
        let encoded = try! encoder.encoded()
        XCTAssertEqual(String(hexFromBytes: encoded.web3.bytes), "0xbc39e7b50000000000000000000000000000000000000000000000000000000000000064")
    }

    func testGivenUInt_WhenInvalidSizeBiggerThan256_ThenFailsEncoding() {
        XCTAssertThrowsError(try encoder.encode(BigUInt(100), staticSize: 257))
    }

    func testGivenPositiveInt_WhenNoExplicitSize_ThenEncodesAs256() {
        XCTAssertNoThrow(try encoder.encode(BigInt(100)))
        let encoded = try! encoder.encoded()
        XCTAssertEqual(String(hexFromBytes: encoded.web3.bytes), "0x9b22c05d0000000000000000000000000000000000000000000000000000000000000064")
    }

    func testGivenPositiveInt_WhenValidSize256_ThenEncodesAs256() {
        XCTAssertNoThrow(try encoder.encode(BigInt(100), staticSize: 256))
        let encoded = try! encoder.encoded()
        XCTAssertEqual(String(hexFromBytes: encoded.web3.bytes), "0x9b22c05d0000000000000000000000000000000000000000000000000000000000000064")
    }

    func testGivenPositiveInt_WhenValidExplicitSize100_ThenEncodesAs100() {
        XCTAssertNoThrow(try encoder.encode(BigInt(100), staticSize: 100))
        let encoded = try! encoder.encoded()
        XCTAssertEqual(String(hexFromBytes: encoded.web3.bytes), "0x868147590000000000000000000000000000000000000000000000000000000000000064")
    }

    func testGivenPositiveInt_WhenInvalidSizeBiggerThan256_ThenFailsEncoding() {
        XCTAssertThrowsError(try encoder.encode(BigInt(100), staticSize: 257))
    }

    func testGivenEmptyData_ThenEncodesCorrectly() {
        XCTAssertNoThrow(try encoder.encode(Data()))
        let encoded = try! encoder.encoded()
        XCTAssertEqual(String(hexFromBytes: encoded.web3.bytes), "0x2f570a2300000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000")
    }

    func testGivenNonEmptyData_ThenEncodesCorrectly() {
        XCTAssertNoThrow(try encoder.encode(Data("hi".web3.bytes)))
        let encoded = try! encoder.encoded()
        XCTAssertEqual(String(hexFromBytes: encoded.web3.bytes), "0x2f570a23000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000026869000000000000000000000000000000000000000000000000000000000000")
    }

    func testGivenStaticSizeData4_ThenEncodesCorrectly() {
        XCTAssertNoThrow(try encoder.encode(Data(hex: "0xffffffff")!, staticSize: 4))
        let encoded = try! encoder.encoded()
        XCTAssertEqual(String(hexFromBytes: encoded.web3.bytes), "0xda67eb8affffffff00000000000000000000000000000000000000000000000000000000")
    }

    func testGivenStaticSizeDataBiggerThan32_ThenFailsEncoding() {
        XCTAssertThrowsError(try encoder.encode(Data(hex: "0xffffffff")!, staticSize: 33))
    }

    func testGivenEmptyArrayOfAddressses_ThenEncodesCorrectly() {
        XCTAssertNoThrow(try encoder.encode([EthereumAddress]()))
        let encoded = try! encoder.encoded()
        XCTAssertEqual(String(hexFromBytes: encoded.web3.bytes), "0xd57498ea00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000")
    }

    func testGivenArrayOfAddressses_ThenEncodesCorrectly() {
        let addresses: [EthereumAddress] = ["0x26fc876db425b44bf6c377a7beef65e9ebad0ec3",
                         "0x25a01a05c188dacbcf1d61af55d4a5b4021f7eed",
                         "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
                         "0x8c2dc702371d73febc50c6e6ced100bf9dbcb029",
                         "0x007eedb5044ed5512ed7b9f8b42fe3113452491e"]

        XCTAssertNoThrow(try encoder.encode(addresses))
        let encoded = try! encoder.encoded()
        XCTAssertEqual(String(hexFromBytes: encoded.web3.bytes), "0xd57498ea0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000500000000000000000000000026fc876db425b44bf6c377a7beef65e9ebad0ec300000000000000000000000025a01a05c188dacbcf1d61af55d4a5b4021f7eed000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0000000000000000000000008c2dc702371d73febc50c6e6ced100bf9dbcb029000000000000000000000000007eedb5044ed5512ed7b9f8b42fe3113452491e")
    }

    func testGivenMultiBytes_ThenEncodesCorrectly() {
        let sigData = Data(hex: "0x450298c35b4713c9722b9b771f67d004ece1d25cbd33534e5932ea88172d23e90600203208a3ef63195f75702b61da1715aa785784c75f7a92958800095081221c")!
        let wallet = EthereumAddress("0xfbbcfe69b3941682d87d6bec0b64099e00d78f8e")
        let data = Data(hex: "0x2df546f4000000000000000000000000fbbcfe69b3941682d87d6bec0b64099e00d78f8e000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000a78a7b5926c52c10f4b7e84d085f1999c5ec89ff000000000000000000000000000000000000000000000000016345785d8a000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000000")!

        let exec = RelayerExecute(from: nil, gasPrice: nil, gasLimit: nil, wallet: wallet, data: data, nonce: .zero, signatures: sigData, _gasPrice: .zero, _gasLimit: .zero)

        let execData = try! exec.transaction().data!
        XCTAssertEqual(execData.web3.hexString, "0xaacaaf88000000000000000000000000fbbcfe69b3941682d87d6bec0b64099e00d78f8e00000000000000000000000000000000000000000000000000000000000000c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c42df546f4000000000000000000000000fbbcfe69b3941682d87d6bec0b64099e00d78f8e000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000a78a7b5926c52c10f4b7e84d085f1999c5ec89ff000000000000000000000000000000000000000000000000016345785d8a000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000041450298c35b4713c9722b9b771f67d004ece1d25cbd33534e5932ea88172d23e90600203208a3ef63195f75702b61da1715aa785784c75f7a92958800095081221c00000000000000000000000000000000000000000000000000000000000000")
    }

    func testGivenArrayOfStaticSizeBytes_ThenEncodesCorrectly() {
        let sigDatas = [
            Data(hex: "0x450298c35b4713c9722b9b771f67d004ece1d25cbd33534e5932ea88172d23e9")!,
            Data(hex: "0x7efef35dcd300eec8819c4ce5cb6b57be685254d583954273c5cc16edee83790")!
        ]
        let signatures = sigDatas.map { Data32(data: $0) }
        let exec = RelayerWithData32Execute(from: nil, gasPrice: nil, gasLimit: nil, signatures: signatures)

        let execData = try! exec.transaction().data!
        XCTAssertEqual(execData.web3.hexString, "0x8af7c64900000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000002450298c35b4713c9722b9b771f67d004ece1d25cbd33534e5932ea88172d23e97efef35dcd300eec8819c4ce5cb6b57be685254d583954273c5cc16edee83790") 
    }

    func testGivenArrayOfBigUInt_ThenEncodesCorrectly() {
        let values = [BigUInt(1), BigUInt(2), BigUInt(3)]

        XCTAssertNoThrow(try encoder.encode(values))
        let encoded = try! encoder.encoded()
        XCTAssertEqual(String(hexFromBytes: encoded.web3.bytes), "0xca16068400000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000003")
    }

    func testGivenArrayOfStrings_ThenEncodesCorrectly() {
        let values = ["abc"]

        do {
            try encoder.encode(values)
            XCTAssertEqual(try encoder.encoded().web3.hexString, "0xe21b90eb00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000036162630000000000000000000000000000000000000000000000000000000000")
        } catch {
            XCTFail()
        }
    }

    func testGivenSimpleTuple_ThenEncodesCorrectly() {
        let tuple = SimpleTuple(address: "0x64d0ea4fc60f27e74f1a70aa6f39d403bbe56793", amount: BigUInt(30))

        do {
            try encoder.encode(tuple)
            XCTAssertEqual(try encoder.encoded().web3.hexString, "0xba71720c00000000000000000000000064d0ea4fc60f27e74f1a70aa6f39d403bbe56793000000000000000000000000000000000000000000000000000000000000001e")
        } catch let error {
            print(error.localizedDescription)
            XCTFail()
        }
    }

    func testGivenDynamicContentTuple_ThenEncodesCorrectly() {
        let tuple = DynamicContentTuple(message: "abc")

        do {
            try encoder.encode(tuple)
            XCTAssertEqual(try encoder.encoded().web3.hexString, "0xd6c9f12a0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000036162630000000000000000000000000000000000000000000000000000000000")
        } catch let error {
            print(error.localizedDescription)
            XCTFail()
        }
    }

    func testGivenTupleAndArgument_ThenEncodesCorrectly() {
        let tuple = DynamicContentTuple(message: "abc")

        do {
            try encoder.encode(tuple)
            try encoder.encode(BigUInt(1))
            XCTAssertEqual(try encoder.encoded().web3.hexString,
                           "0x969569a200000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000036162630000000000000000000000000000000000000000000000000000000000")
        } catch let error {
            print(error.localizedDescription)
            XCTFail()
        }
    }

    func test_GivenLongTupleArgument_ThenEncodesCorrectly() {
        let tuple = LongTuple(value1: "https://ethereum.org/abcde",
                              value2: "https://ethereum.org/xyz",
                              value3: Data(hex: "0x1c8aff950685c2ed4bc3174f3472287b56d9517b9c948127319a09a7a36deac8")!,
                              value4: Data(hex: "0x8452c9b9140222b08593a26daa782707297be9f7b3e8281d7b4974769f19afd0")!)

        let encoder = ABIFunctionEncoder("TestLongTuple")

        try? encoder.encode(tuple)
        XCTAssertEqual(try? encoder.encoded().web3.hexString, "0xfe83fc010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000c01c8aff950685c2ed4bc3174f3472287b56d9517b9c948127319a09a7a36deac88452c9b9140222b08593a26daa782707297be9f7b3e8281d7b4974769f19afd0000000000000000000000000000000000000000000000000000000000000001a68747470733a2f2f657468657265756d2e6f72672f6162636465000000000000000000000000000000000000000000000000000000000000000000000000001868747470733a2f2f657468657265756d2e6f72672f78797a0000000000000000")

    }

    func test_GivenSomeArgumentsAndLongTuple_ThenEncodesCorrectly() {
        let tuple = LongTuple(value1: "https://ipfs.fleek.co/ipfs/bafybeib7trltlf567dqq3jvok73k7vpnkxdq3gf6evj2ltezzzzhquc6ea",
                              value2: "https://ipfs.fleek.co/ipfs/bafybeiezpaegcxyltpw3qjmxtfxqiaddqbrdrzoyvmbaghqdhwhuuliciy",
                              value3: Data(hex: "0x7efef35dcd300eec8819c4ce5cb6b57be685254d583954273c5cc16edee83790")!,
                              value4: Data(hex: "0xba42a7d804d9eff383efb1864514f5f15c82f1c333a777dd8f76dba1c1977029")!)

        let encoder = ABIFunctionEncoder("TestLongTuple")
        try? encoder.encode(tuple)
        try? encoder.encode(BigUInt(0))
        try? encoder.encode(BigUInt(hex: "0xa688906bd8b00000")!)
        try? encoder.encode(BigUInt(hex: "0x4c53ecdc18a600000")!)
        XCTAssertEqual(try? encoder.encoded().web3.hexString, "0x51746d2300000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a688906bd8b00000000000000000000000000000000000000000000000000004c53ecdc18a600000000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000001007efef35dcd300eec8819c4ce5cb6b57be685254d583954273c5cc16edee83790ba42a7d804d9eff383efb1864514f5f15c82f1c333a777dd8f76dba1c1977029000000000000000000000000000000000000000000000000000000000000005668747470733a2f2f697066732e666c65656b2e636f2f697066732f62616679626569623774726c746c66353637647171336a766f6b37336b3776706e6b7864713367663665766a326c74657a7a7a7a6871756336656100000000000000000000000000000000000000000000000000000000000000000000000000000000005668747470733a2f2f697066732e666c65656b2e636f2f697066732f62616679626569657a706165676378796c74707733716a6d78746678716961646471627264727a6f79766d62616768716468776875756c6963697900000000000000000000")

    }

    func testGivenArrayOfTuples_ThenEncodesCorrectly() {
        let tuples = [
            SimpleTuple(address: "0x64d0eA4FC60f27E74f1a70Aa6f39D403bBe56793", amount: 30),
            SimpleTuple(address: "0x3C1Bd6B420448Cf16A389C8b0115CCB3660bB854", amount: 120)]

        do {
            try encoder.encode(tuples)
            XCTAssertEqual(try encoder.encoded().web3.hexString,
                           "0xae4f5efa0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000200000000000000000000000064d0ea4fc60f27e74f1a70aa6f39d403bbe56793000000000000000000000000000000000000000000000000000000000000001e0000000000000000000000003c1bd6b420448cf16a389c8b0115ccb3660bb8540000000000000000000000000000000000000000000000000000000000000078")
        } catch let error {
            print(error.localizedDescription)
            XCTFail()
        }
    }

    // See example: https://solidity.readthedocs.io/en/v0.6.11/abi-spec.html#use-of-dynamic-types
    func test_GivenArrayOfArraysSample_ThenEncodesCorrectly() {
        encoder = ABIFunctionEncoder("f")

        do {
            try encoder.encode(BigUInt(hex: "0x123")!)
            try encoder.encode([UInt32]([0x456, 0x789]))
            try encoder.encode("1234567890".data(using: .utf8)!, staticSize: 10)
            try encoder.encode("Hello, world!".data(using: .utf8)!)
            XCTAssertEqual(try encoder.encoded().web3.hexString,
                           "0x8be6524600000000000000000000000000000000000000000000000000000000000001230000000000000000000000000000000000000000000000000000000000000080313233343536373839300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e0000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000004560000000000000000000000000000000000000000000000000000000000000789000000000000000000000000000000000000000000000000000000000000000d48656c6c6f2c20776f726c642100000000000000000000000000000000000000")
        } catch {
            XCTFail()
        }
    }

    func test_GivenArrayOfComplexTuples_WhenEncodesOneEntry_ThenEncodesCorrectly() {
        do {
            let tuple = ComplexTupleWithArray(address: "0xdF136715f7bafD40881cFb16eAa5595C2562972b", amount: 2, owners: [SimpleTuple(address: "0xdF136715f7bafD40881cFb16eAa5595C2562972b", amount: 100)])

            try encoder.encode([tuple])
            XCTAssertEqual(try encoder.encoded().web3.hexString,
                           "0x07e0fd75000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000df136715f7bafd40881cfb16eaa5595c2562972b000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000001000000000000000000000000df136715f7bafd40881cfb16eaa5595c2562972b0000000000000000000000000000000000000000000000000000000000000064")
        } catch {
            XCTFail()
        }
    }

    func test_GivenArrayOfComplexTuples_WhenEncodesTwoEntries_ThenEncodesCorrectly() {
        do {
            let tuple1 = ComplexTupleWithArray(address: "0xdF136715f7bafD40881cFb16eAa5595C2562972b", amount: 2, owners: [SimpleTuple(address: "0x4bf21a47b608841e974ff4147fd1a005da7fdf9b", amount: 100)])
            let tuple2 = ComplexTupleWithArray(address: "0x69F84b91E7107206E841748C2B52294A1176D45e", amount: 3, owners: [SimpleTuple(address: "0xc07d381fFadB957e0FC9218AaBa88556f5C4BB7a", amount: 200)])
            try encoder.encode([tuple1, tuple2])
            XCTAssertEqual(try encoder.encoded().web3.hexString,
                           "0x07e0fd750000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000100000000000000000000000000df136715f7bafd40881cfb16eaa5595c2562972b0000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000010000000000000000000000004bf21a47b608841e974ff4147fd1a005da7fdf9b000000000000000000000000000000000000000000000000000000000000006400000000000000000000000069f84b91e7107206e841748c2b52294a1176d45e000000000000000000000000000000000000000000000000000000000000000300000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000001000000000000000000000000c07d381ffadb957e0fc9218aaba88556f5c4bb7a00000000000000000000000000000000000000000000000000000000000000c8")
        } catch {
            XCTFail()
        }
    }

    func test_GivenLongTupleAndSimpleTupleOfTuples_EncodesCorrectly() {
        let tuple = LongTuple(value1: "https://ipfs.fleek.co/ipfs/bafybeib7trltlf567dqq3jvok73k7vpnkxdq3gf6evj2ltezzzzhquc6ea",
                              value2: "https://ipfs.fleek.co/ipfs/bafybeiezpaegcxyltpw3qjmxtfxqiaddqbrdrzoyvmbaghqdhwhuuliciy",
                              value3: Data(hex: "0x7efef35dcd300eec8819c4ce5cb6b57be685254d583954273c5cc16edee83790")!,
                              value4: Data(hex: "0xba42a7d804d9eff383efb1864514f5f15c82f1c333a777dd8f76dba1c1977029")!)

        let tupleOfTuples = TupleOfTuples(value1: NumberTuple(value: 0),
                                                value2: NumberTuple(value: BigUInt(hex: "0xa688906bd8b00000")!),
                                                value3: NumberTuple(value: BigUInt(hex: "0x4c53ecdc18a600000")!))

        let encoder = ABIFunctionEncoder("mint")
        try? encoder.encode(tuple)
        try? encoder.encode(tupleOfTuples)
        XCTAssertEqual(try? encoder.encoded().web3.hexString, "0x2cca323700000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a688906bd8b00000000000000000000000000000000000000000000000000004c53ecdc18a600000000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000001007efef35dcd300eec8819c4ce5cb6b57be685254d583954273c5cc16edee83790ba42a7d804d9eff383efb1864514f5f15c82f1c333a777dd8f76dba1c1977029000000000000000000000000000000000000000000000000000000000000005668747470733a2f2f697066732e666c65656b2e636f2f697066732f62616679626569623774726c746c66353637647171336a766f6b37336b3776706e6b7864713367663665766a326c74657a7a7a7a6871756336656100000000000000000000000000000000000000000000000000000000000000000000000000000000005668747470733a2f2f697066732e666c65656b2e636f2f697066732f62616679626569657a706165676378796c74707733716a6d78746678716961646471627264727a6f79766d62616768716468776875756c6963697900000000000000000000")

    }
}

struct SimpleTuple: ABITuple, Equatable {
    static var types: [ABIType.Type] { [EthereumAddress.self, BigUInt.self] }

    var address: EthereumAddress
    var amount: BigUInt

    init(address: EthereumAddress,
         amount: BigUInt) {
        self.address = address
        self.amount = amount
    }

    init?(values: [ABIDecoder.DecodedValue]) throws {
        self.address = try values[0].decoded()
        self.amount = try values[1].decoded()
    }

    func encode(to encoder: ABIFunctionEncoder) throws {
        try encoder.encode(address)
        try encoder.encode(amount)
    }

    var encodableValues: [ABIType] { [address, amount] }
}

struct LongTuple: ABITuple, Equatable {
    static var types: [ABIType.Type] { [String.self, String.self, Data32.self, Data32.self] }

    var value1: String
    var value2: String
    var value3: Data
    var value4: Data

    init(value1: String,
         value2: String,
         value3: Data,
         value4: Data) {
        self.value1 = value1
        self.value2 = value2
        self.value3 = value3
        self.value4 = value4
    }

    init?(values: [ABIDecoder.DecodedValue]) throws {
        self.value1 = try values[0].decoded()
        self.value2 = try values[1].decoded()
        self.value3 = try values[2].decoded()
        self.value4 = try values[3].decoded()
    }

    func encode(to encoder: ABIFunctionEncoder) throws {
        try encoder.encode(value1)
        try encoder.encode(value2)
        try encoder.encode(value3, staticSize: 32)
        try encoder.encode(value4, staticSize: 32)
    }

    var encodableValues: [ABIType] { [value1, value2, value3, value4] }
}

struct DynamicContentTuple: ABITuple, Equatable {
    static var types: [ABIType.Type] { [String.self] }

    var message: String

    init(message: String) {
        self.message = message
    }

    init?(values: [ABIDecoder.DecodedValue]) throws {
        self.message = try values[0].decoded()
    }

    func encode(to encoder: ABIFunctionEncoder) throws {
        try encoder.encode(message)
    }

    var encodableValues: [ABIType] { [message] }
}

private struct ComplexTupleWithArray: ABITuple {
    static var types: [ABIType.Type] { [EthereumAddress.self, BigUInt.self, ABIArray<SimpleTuple>.self] }

    var address: EthereumAddress
    var amount: BigUInt
    var owners: [SimpleTuple]

    init(address: EthereumAddress,
         amount: BigUInt,
         owners: [SimpleTuple]) {
        self.address = address
        self.amount = amount
        self.owners = owners
    }

    init?(values: [ABIDecoder.DecodedValue]) throws {
        self.address = try values[0].decoded()
        self.amount = try values[1].decoded()
        self.owners = try values[2].decodedArray()
    }

    func encode(to encoder: ABIFunctionEncoder) throws {
        try encoder.encode(address)
        try encoder.encode(amount)
        try encoder.encode(owners)
    }

    var encodableValues: [ABIType] { [address, amount, ABIArray(values: owners)] }
}

private struct RelayerExecute: ABIFunction {
    static let name = "execute"
    let contract = EthereumAddress.zero
    let from: EthereumAddress?
    var gasPrice: BigUInt?
    var gasLimit: BigUInt?

    struct Response: ABIResponse {
        static var types: [ABIType.Type] = []

        init?(values: [ABIDecoder.DecodedValue]) throws {

        }
    }

    let wallet: EthereumAddress
    let data: Data
    let nonce: BigUInt
    let signatures: Data
    let _gasPrice: BigUInt
    let _gasLimit: BigUInt

    func encode(to encoder: ABIFunctionEncoder) throws {
        try encoder.encode(wallet)
        try encoder.encode(data)
        try encoder.encode(nonce)
        try encoder.encode(signatures)
        try encoder.encode(_gasPrice)
        try encoder.encode(_gasLimit)
    }
}

private struct RelayerWithData32Execute: ABIFunction {
    static let name = "execute"
    let contract = EthereumAddress.zero
    let from: EthereumAddress?
    var gasPrice: BigUInt?
    var gasLimit: BigUInt?

    struct Response: ABIResponse {
        static var types: [ABIType.Type] = []

        init?(values: [ABIDecoder.DecodedValue]) throws {

        }
    }

    let signatures: [Data32]

    func encode(to encoder: ABIFunctionEncoder) throws {
        try encoder.encode(signatures)
    }
}


struct NumberTuple: ABITuple, Equatable {
    func encode(to encoder: ABIFunctionEncoder) throws {
        try encoder.encode(value)
    }

    static var types: [ABIType.Type] { [BigUInt.self] }

    var value: BigUInt

    init(value: BigUInt) {
        self.value = value
    }

    init?(values: [ABIDecoder.DecodedValue]) throws {
        self.value = try values[0].decoded()
    }

    var encodableValues: [ABIType] { [value] }
}

struct TupleOfTuples: ABITuple {
    func encode(to encoder: ABIFunctionEncoder) throws {
        try encoder.encode(value1)
        try encoder.encode(value2)
        try encoder.encode(value3)
    }

    static var types: [ABIType.Type] { [NumberTuple.self, NumberTuple.self, NumberTuple.self] }

    var value1: NumberTuple
    var value2: NumberTuple
    var value3: NumberTuple

    init(value1: NumberTuple,
         value2: NumberTuple,
         value3: NumberTuple) {
        self.value1 = value1
        self.value2 = value2
        self.value3 = value3
    }

    init?(values: [ABIDecoder.DecodedValue]) throws {
        self.value1 = try values[0].decoded()
        self.value2 = try values[1].decoded()
        self.value3 = try values[2].decoded()
    }

    var encodableValues: [ABIType] { [value1, value2, value3] }
}
