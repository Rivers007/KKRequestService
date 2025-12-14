//
//  RequestConfigError.swift
//  KKRequestServiceDemo
//
//  Created by 江贵铸 on 2025/12/3.
//

import Foundation
import Alamofire

// MARK: - RequestError

public enum KKErrorCode {
    case unknown
    case networkUnavailable
    case invalidProtocol
    case emptyURL
    case http(Int)

}


public protocol RequestErrorProtocol: Error, LocalizedError,Sendable {
    init(code: KKErrorCode?, error: Alamofire.AFError?)
    init(code: KKErrorCode?)
    var code: KKErrorCode? { get set}
    var error: Alamofire.AFError? {get set}
    var responseModel: (any ResponseDecodable)? { get set}
    var responseObj: Any? { get set}
    
    var message: String{get}
    
}
public struct DefaultRequestError: RequestErrorProtocol {
   
    public init() {}
    public init(code: KKErrorCode?) {
        self.code = code
    }
    public init(code: KKErrorCode?, error: Alamofire.AFError? = nil) {
        self.code = code
        self.error = error
    }
    
    public var responseModel: (any ResponseDecodable)?
    public var responseObj: Any?
    
    public var code: KKErrorCode? = .unknown
    
    public var error: Alamofire.AFError?
    public var message: String{
        ""
    }

}


