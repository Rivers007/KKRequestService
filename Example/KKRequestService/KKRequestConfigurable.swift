//
//  KKRequestConfigurable.swift
//  KKRequestServiceDemo
//
//  Created by 江贵铸 on 2025/12/6.
//
import Foundation
import KKRequestService

struct KKRequestConfigurable: RequestConfigurable{
    func encryptCommonParams(_ parameters: [String : Any], request: KKBaseRequestInfo) -> [String : Any] {
        parameters
    }
    
    func encryptCommonHeader(_ headers: [String : String], request: KKBaseRequestInfo) -> [String : String] {
        var headersDict = globalHeaders ?? [:]
        if !headers.isEmpty {
            headersDict = headersDict.merging(headers, uniquingKeysWith: { _, new in new })
        }
        if APIEnum.noTokenPaths.contains(request.path) == false {
            headersDict["token"] = token
        }
        return headersDict
    }
    
    func requestSuccess(request: KKBaseRequestInfo, response: any ResponseDecodable) {
        if let m = response as? BaseResponseModel {
            KKPrint(m.retCode!)
        }
    }
    
    func requestFailure(request: KKBaseRequestInfo, error: any RequestErrorProtocol) {
        switch error.code {
        case .http(let statusCode):
            if statusCode == 200, let m = error.responseModel as? BaseResponseModel {
               KKPrint( m.retCode!)
            }
        default:
            break
        }
    }
    
    
    var baseURL: String?{
        return "http://doc-dev.imkktv.com/"
    }
    
    var token: String?{
        nil
    }
    
    var timeout: TimeInterval{
        30
    }
    
    var globalHeaders: [String : String]?{
        ["userId":"9999955794","versionCode":"180","Content-Type":"application/x-www-form-urlencoded;charset=UTF-8","loginType":"0"]
    }
    
}

public class BaseResponseModel: KKDecodable{
    required public init() {}
    
    public var success: Bool?
    public var retCode: String?
    public var retMsg: String?
    

}

public class ResponseModel<T: Decodable>: BaseResponseModel, ResponseDecodable{
    
    // 实现必需的初始化器
    required public init() {
        super.init()
    }
    
    // 实现 Decodable 所需的初始化器
    required public init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    public init(data: T? = nil) {
        super.init()
        self.data = data
    }
    
    public var data: T?
    public var isBusinessSuccess: Bool{
         success ?? false
    }
    
    public var responseJson: String = ""
    
    // 编码键
    private enum CodingKeys: String, CodingKey {
        case data
        case responseJson
    }
}


public struct KKRequestError: RequestErrorProtocol {
    public var message: String{
        ""
    }
    
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
    
}

public struct KKNetworkStrategy: NetworkStrategy {
    
    
    public init() {}
    
    public func shouldRetry(_ request: URLRequest, with response: HTTPURLResponse) -> Bool {
        false
    }
    
    public func handleSSLPinningFailure(reason _: AFError.ServerTrustFailureReason) {}
    
    public var serverTrustManager: Alamofire.ServerTrustManager? {
        nil
    }
}
