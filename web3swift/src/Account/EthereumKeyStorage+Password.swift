import Foundation

public extension EthereumKeyStorageProtocol {
    func encryptAndStorePrivateKey(key: Data, keystorePassword: String) throws {
        let encodedKey = try KeystoreUtil.encode(privateKey: key, password: keystorePassword)
        let address = KeyUtil.generateAddress(from: encodedKey)
        try storePrivateKey(key: encodedKey, with: address.value)
    }

    func loadAndDecryptPrivateKey(for address: String, keystorePassword: String) throws -> Data {
        let encryptedKey = try loadPrivateKey(for: address)
        return try KeystoreUtil.decode(data: encryptedKey, password: keystorePassword)
    }
}
