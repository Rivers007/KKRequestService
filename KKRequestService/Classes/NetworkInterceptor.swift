//
//  NetworkInterceptor.swift
//  KKRequestServiceDemo
//
//  Created by 江贵铸 on 2025/11/30.
//

import Alamofire
import Foundation

public final class NetworkInterceptor: RequestInterceptor, @unchecked Sendable {
    private let config: RequestConfiguration
    private let strategy: NetworkStrategy?

    public init(config: RequestConfiguration, strategy: NetworkStrategy?) {
        self.config = config
        self.strategy = strategy
    }

    public func adapt(
            _ urlRequest: URLRequest,
            for _: Session,
            completion: @escaping (Result<URLRequest, Error>) -> Void
    ) {
        var urlRequest = urlRequest
        if let globalHeaders = config.globalHeaders {
            globalHeaders.forEach {
                urlRequest.setValue($1, forHTTPHeaderField: $0)
            }
        }
        completion(.success(urlRequest))
    }

    public func retry(_ request: Request, for _: Session, dueTo _: Error, completion: @escaping (RetryResult) -> Void) {
        guard let response = request.task?.response as? HTTPURLResponse,
              let urlRequest = request.request,
              let strategy
        else {
            completion(.doNotRetry)
            return
        }

        if strategy.shouldRetry(urlRequest, with: response) {
            completion(.retry)
        } else {
            completion(.doNotRetry)
        }
    }
}
