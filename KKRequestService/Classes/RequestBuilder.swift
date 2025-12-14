//
//  RequestBuilder.swift
//  KKRequestServiceDemo
//
//  Created by 江贵铸 on 2025/12/3.
//
import Alamofire


// MARK: - RequestEncoding
public enum RequestEncoding {
    case urlDefault
    case urlQueryString
    case urlHttpBody
    case json
    case jsonPrettyPrinted
    
    var alamofireEncoding: Alamofire.ParameterEncoding {
        switch self {
        case .urlDefault:
            return URLEncoding.default
        case .urlQueryString:
            return URLEncoding.queryString
        case .urlHttpBody:
            return URLEncoding.httpBody
        case .json:
            return JSONEncoding.default
        case .jsonPrettyPrinted:
            return JSONEncoding.prettyPrinted
        }
    }
}

// MARK: - Base KKRequestInfo (non-generic)
public class KKBaseRequestInfo {
    public var requestId: String? = nil
    public var baseUrl: String?
    public let path: String
    public let method: HTTPMethod
    public let headers: [String: String]
    public let parameters: [String: Any]
    public let encoding: ParameterEncoding
    
    public var multipartFormDataClosure: ((MultipartFormData) -> Void)?
    
    public var afRequest: DataRequest?
    
    public init(requestId: String? = nil,
                baseUrl: String? = nil,
                path: String,
                method: HTTPMethod,
                headers: [String: String],
                parameters: [String: Any],
                encoding: ParameterEncoding,
                multipartFormDataClosure: ((MultipartFormData) -> Void)? = nil) {
        self.requestId = requestId
        self.baseUrl = baseUrl
        self.path = path
        self.method = method
        self.headers = headers
        self.parameters = parameters
        self.encoding = encoding
        self.multipartFormDataClosure = multipartFormDataClosure
    }
}

// MARK: - Generic KKRequestInfo (继承自基础类)
public class KKRequestInfo<T: ResponseDecodable>: KKBaseRequestInfo {
    // 继承所有基础功能，只是添加类型约束以便在需要时使用
}

// MARK: - RequestBuilder

public class RequestBuilder<T: ResponseDecodable> {
    private(set) var requestId: String = NetworkService.makeRequestId()
    private(set) var baseUrl: String?
    private(set) var path: String
    private(set) var method: HTTPMethod = .get
    private(set) var headers: [String: String] = [:]
    private(set) var parameters: [String: Any] = [:]
    
    private(set) var encoding: Alamofire.ParameterEncoding = URLEncoding.default
    
    private var timeout: TimeInterval?
    
    public init(path: APIConfigurable) {
        self.path = path.path
    }
    public func setRequestId(_ id: String) -> RequestBuilder {
        self.requestId = id
        return self
    }
    public func setBaseUrl(_ url: String) -> RequestBuilder {
        self.baseUrl = url
        return self
    }
    
    public func setMethod(_ method: HTTPMethod) -> RequestBuilder {
        self.method = method
        return self
    }
    
    public func setHeaders(_ headers: [String: String]) -> RequestBuilder {
        self.headers = headers
        return self
    }
    
    public func setParameters(_ parameters: [String: Any]) -> RequestBuilder {
        guard validateParameters(parameters) else {
            assertionFailure("Invalid parameters")
            return self
        }
        self.parameters = parameters
        return self
    }
    
    /// Sets the parameter encoding for the request.
    /// - Parameter encoding: The parameter encoding to use
    /// - Returns: The RequestBuilder instance for method chaining
    public func setEncoding(_ encoding: RequestEncoding) -> RequestBuilder {
        self.encoding = encoding.alamofireEncoding
        return self
    }
    
    @discardableResult
    public func sendRequest(successClosure: ((T)->Void)? = nil,
                            failureClosure: ((any RequestErrorProtocol)->Void)? = nil) -> String {
        let request = build()
        NetworkService.shared.sendRequest(request: request) { result in
            switch result{
            case .success(let response):
                print("")
                successClosure?(response)
                break
            case .failure(let error):
                print("")
                if let requestError = error as? RequestErrorProtocol {
                    failureClosure?(requestError)
                }
               
                break
            }
        }
        return requestId
    }
    
    // MARK: - upload file
    
    private(set) var multipartFormDataClosure: ((MultipartFormData) -> Void)?
    
    public func setMultipartFormData(
        _ multipartFormDataClosure: @escaping (MultipartFormData) -> Void
    ) -> RequestBuilder {
        self.multipartFormDataClosure = multipartFormDataClosure
        return self
    }
    
    /// - Parameters:
    ///   - uploadProgress: upload progress, in main queue
    ///   - completion: upload completion handler
    @discardableResult
    public func upload(
        uploadProgress: ((Progress) -> Void)?,
        completion: @escaping (Result<T, Error>) -> Void
    ) -> String{
        let request = build()
        NetworkService.shared.uploadFile(
            request: request,
            uploadProgress: uploadProgress,
            completion: completion
        )
        return requestId
    }
    
    public func setTimeout(_ timeout: TimeInterval) -> RequestBuilder {
        self.timeout = timeout
        return self
    }
}

// MARK: - Build

extension RequestBuilder {
    fileprivate func build() -> KKRequestInfo<T> {
        KKRequestInfo<T>(
            requestId: requestId,
            baseUrl: baseUrl,
            path: path,
            method: method,
            headers: headers,
            parameters: parameters,
            encoding: encoding,
            multipartFormDataClosure: multipartFormDataClosure
        )
    }
    
    fileprivate func validateParameters(_: [String: Any]) -> Bool {
        true
    }
}

extension RequestBuilder{
    // 通过请求id取消请求
    public static func cancel(id: String) {
        NetworkService.shared.cancel(id: id)
    }
    // 取消所有请求
    public static func cancelAll(id: String) {
        NetworkService.shared.cancelAll()
    }
    
}
