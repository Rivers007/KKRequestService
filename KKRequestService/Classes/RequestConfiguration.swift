//
//  RequestConfiguration.swift
//  KKRequestServiceDemo
//
//  Created by 江贵铸 on 2025/11/30.
//

import Foundation

public  class RequestConfiguration {
    
    public static let shared = RequestConfiguration()
    
    public var globalHeaders: [String: String]? {
            requestConfig?.globalHeaders
    }
    
    private init() {}
    
    public private(set) var requestConfig: RequestConfigurable?
    public private(set) var strategy: NetworkStrategy?
    public private(set) var requestError: RequestErrorProtocol.Type = DefaultRequestError.self
    
    public static func combine(
        by requestConfig: RequestConfigurable,
        strategy: NetworkStrategy = DefaultNetworkStrategy(),
        requestError: RequestErrorProtocol.Type = DefaultRequestError.self
    ) {
        shared.requestConfig = requestConfig
        shared.strategy = strategy
        shared.requestError = requestError

    }
    
}
