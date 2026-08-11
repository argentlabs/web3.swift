//
//  web3.swift
//  Copyright © Argent Labs Limited. All rights reserved.
//

import Logging
import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

public class EthereumHttpClient: BaseEthereumClient, @unchecked Sendable {
    let networkQueue: OperationQueue

    public init(
        url: URL,
        headers: [String: String]? = nil,
        sessionConfig: URLSessionConfiguration = URLSession.shared.configuration,
        logger: Logger? = nil,
        network: EthereumNetwork,
        maxBlockRange: Int? = nil
    ) {
        let networkQueue = OperationQueue()
        networkQueue.name = "web3swift.client.networkQueue"
        networkQueue.maxConcurrentOperationCount = 4
        self.networkQueue = networkQueue

        let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: networkQueue)
        super.init(
            networkProvider: HttpNetworkProvider(session: session, url: url, headers: headers),
            url: url,
            logger: logger,
            network: network,
            maxBlockRange: maxBlockRange
        )
    }
}
