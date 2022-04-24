//  Created by Rinat Enikeev on 24.04.2022.

import XCTest
import BigInt
@testable import web3

class ABIConstructorEncoderTests: XCTestCase {
    var encoder: ABIConstructorEncoder!

    override func setUp() {
        encoder = ABIConstructorEncoder(TestConfig.erc20Bytecode.web3.hexData!)
    }

    // reference: https://ropsten.etherscan.io/address/0x583cbbb8a8443b38abcc0c956bece47340ea1367#code
    func testGivenBokkyParams_ThenEncodesCorrectly() {
        XCTAssertNoThrow(try encoder.encode("BokkyPooBah Test Token"))
        XCTAssertNoThrow(try encoder.encode("BOKKY"))
        XCTAssertNoThrow(try encoder.encode(UInt8(18)))
        let encoded = try! encoder.encoded()
        XCTAssertEqual(
            String(hexFromBytes: encoded.web3.bytes),
            "0x" + TestConfig.erc20Bytecode + "000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000120000000000000000000000000000000000000000000000000000000000000016426f6b6b79506f6f426168205465737420546f6b656e000000000000000000000000000000000000000000000000000000000000000000000000000000000005424f4b4b59000000000000000000000000000000000000000000000000000000"
        )
    }
}
