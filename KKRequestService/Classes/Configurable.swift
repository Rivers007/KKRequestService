//
//  Configurable.swift
//  KKRequestServiceDemo
//
//  Created by 江贵铸 on 2025/11/30.
//
import Alamofire
import Foundation
import SmartCodable

// MARK: - APIConfigurable

public protocol APIConfigurable: Sendable {
    static var noTokenPaths: [String] { get }
    var path: String { get }
}

public typealias KKCodable = SmartCodable
public typealias KKDecodable = SmartDecodable
public typealias KKEnumCodable = SmartCaseDefaultable
public typealias KKAny = SmartAny


public protocol ResponseJson{
    var responseJson: String { get set }
}

// MARK: - ResponseDecodable

public protocol ResponseDecodable:ResponseJson, KKDecodable {
    /// static func decode(from data: Data) throws -> Self
    associatedtype DataType

    var isBusinessSuccess: Bool { get }
    var data: DataType? { get set }
    
}


public protocol RequestConfigurable: Sendable {
    var baseURL: String? { get }

    var token: String? { get }
    var timeout: TimeInterval { get }
    var globalHeaders: [String: String]? { get }
    func encryptCommonParams(_ parameters: [String : Any], request: KKBaseRequestInfo) -> [String : Any]
    func encryptCommonHeader(_ headers: [String : String], request: KKBaseRequestInfo) -> [String : String]
    func requestSuccess(request: KKBaseRequestInfo, response: any ResponseDecodable)
    func requestFailure(request: KKBaseRequestInfo, error: any RequestErrorProtocol)
}

public protocol NetworkStrategy: Sendable {
    var serverTrustManager: ServerTrustManager? { get }
    func handleSSLPinningFailure(reason: AFError.ServerTrustFailureReason)

    func shouldRetry(_ request: URLRequest, with response: HTTPURLResponse) -> Bool

}


// MARK: - DefaultResponseModel
public struct DefaultResponseModel<T: Decodable>: ResponseDecodable{
    public init() {}
 
    public init(data: T? = nil) {
        self.data = data
    }
    
    public var data: T?
    public var isBusinessSuccess: Bool{
       false
    }
    
    public var responseJson: String = ""
  
}

// MARK: - Type Aliases for Convenience
/// 简化的 KKRequestInfo，不需要泛型约束
public typealias SimpleKKRequestInfo = KKBaseRequestInfo

// MARK: - DefaultNetworkStrategy
public struct DefaultNetworkStrategy: NetworkStrategy {
    
    
    public init() {}

    public func shouldRetry(_ request: URLRequest, with response: HTTPURLResponse) -> Bool {
        false
    }
    
    public func handleSSLPinningFailure(reason _: AFError.ServerTrustFailureReason) {}

    public var serverTrustManager: Alamofire.ServerTrustManager? {
        nil
    }
}
