//
//  web3.swift
//  Copyright © 2022 Argent Labs Limited. All rights reserved.
//

import Logging
import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

public class EthereumHttpClient: BaseEthereumClient {
    let networkQueue: OperationQueue

    public init(
        url: URL,
        sessionConfig: URLSessionConfiguration = URLSession.shared.configuration,
        logger: Logger? = nil,
        network: EthereumNetwork? = nil
    ) {
        let networkQueue = OperationQueue()
        networkQueue.name = "web3swift.client.networkQueue"
        networkQueue.maxConcurrentOperationCount = 4
        self.networkQueue = networkQueue

        let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: networkQueue)
        super.init(networkProvider: HttpNetworkProvider(session: session, url: url), url: url, logger: logger, network: network)
    }
}
