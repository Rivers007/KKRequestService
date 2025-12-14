//
//  NetworkService.swift
//  KKRequestServiceDemo
//
//  Created by 江贵铸 on 2025/11/29.
//

import Foundation
import Alamofire
import Reachability
import SmartCodable

public class NetworkService {
    // key: requestId, value: Request
    private var requests: [String: Request] = [:]
    // 读写锁（并发队列 + barrier）
    private let lockQueue = DispatchQueue(label: "com.kk.networkRequest.lock", attributes: .concurrent)
    
    public static let shared = NetworkService()
    public var reachability = try? Reachability()
    public let sharedSession: Alamofire.Session = {
        
        let requestConfig = RequestConfiguration.shared.requestConfig
        let timeout = requestConfig?.timeout ?? 30
        let requestStrategy = RequestConfiguration.shared.strategy
        let logger = NetworkLogger()
        
        return Alamofire.Session(
            configuration: createSessionConfig(timeout: timeout, globalHeaders: requestConfig?.globalHeaders),
            interceptor: NetworkInterceptor(config: RequestConfiguration.shared, strategy: requestStrategy),
            serverTrustManager: requestStrategy?.serverTrustManager,eventMonitors: [logger]
        )
    }()
    
    public var networkStatusHandler: ((NetworkReachabilityManager.NetworkReachabilityStatus) -> Void)?
    
    private init() {
        
        reachability?.whenReachable = { reachability in
            KKPrint("=====>[NetworkService] Network reachable: \(reachability.connection)")
        }
        reachability?.whenUnreachable = { _ in
            KKPrint("=====>[NetworkService] Network unreachable")
        }
        
        do {
            try reachability?.startNotifier()
        } catch {
            KKPrint("=====> Unable to start notifier !!!!!!!")
        }
        setupNetworkMonitoring()
    }
    
    private func setupNetworkMonitoring() {
        let manager = NetworkReachabilityManager()
        manager?.startListening {[weak self] status in
            self?.networkStatusHandler?(status)
        }
    }
    
    public func sendRequest<T: KKDecodable>(
        request: KKRequestInfo<T>,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        send(request: request, completion: completion)
    }

    public func uploadFile<T: KKDecodable>(
        request: KKRequestInfo<T>,
        uploadProgress: ((Progress) -> Void)?,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        send(request: request, actionType: .upload, uploadProgress: uploadProgress, completion: completion)
    }
    
}

private extension NetworkService{
    enum RequestType {
        case netRequest
        case upload
    }

    
    func send<T: KKDecodable>(
        request: KKRequestInfo<T>,
        actionType: RequestType = .netRequest,
        uploadProgress: ((Progress) -> Void)? = nil,
        
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        let configuration = RequestConfiguration.shared

        // check network status
        guard reachability?.connection != .unavailable else {
            let requestError = configuration.requestError.init(code: .networkUnavailable)
            completion(.failure(requestError))
            return
        }

        guard var baseURL = configuration.requestConfig?.baseURL, isValidURL(baseURL) else {
            let requestError = configuration.requestError.init(code: .invalidProtocol)
            completion(.failure(requestError))
            return
        }
        
        if let url = request.baseUrl {
            baseURL = url
        }
        // url string
        let urlString = baseURL + request.path
        guard let url = URL(string: urlString) else {
            let requestError = configuration.requestError.init(code: .emptyURL)
            completion(.failure(requestError))
            return
        }

        // encrypted params
        let encryptedParams = configuration.requestConfig?.encryptCommonParams(request.parameters, request: request)

        // headers
        let headers: [String: String] = configuration.requestConfig?.encryptCommonHeader(request.headers, request: request) ?? [:]

        let afRequest: Alamofire.DataRequest
        switch actionType {
        case .netRequest:
            afRequest = sharedSession
                .request(url,
                         method: request.method,
                         parameters: encryptedParams,
                         encoding: request.encoding,
                         headers: HTTPHeaders(headers))
                .validate(statusCode: 200 ..< 300)
                .validate(contentType: ["application/json"])
        case .upload:
            guard let multipartFormDataClosure = request.multipartFormDataClosure else {
                assertionFailure("Upload request multipartFormDataClosure cannot be nil.")
                return
            }

            afRequest = sharedSession
                .upload(multipartFormData: { multipartFormData in
                            // add additional request paramters
                            if let encryptedParams {
                                encryptedParams.enumerated().forEach {
                                    if let data = "\($1.value)".data(using: .utf8) {
                                        multipartFormData.append(data, withName: $1.key)
                                    }
                                }
                            }
                            multipartFormDataClosure(multipartFormData)
                            debugPrint(multipartFormData)
                        },
                        to: url,
                        method: request.method,
                        headers: HTTPHeaders(headers))

                .uploadProgress { progress in
                    print("Upload Progress: \(progress.fractionCompleted)")
                    uploadProgress?(progress)
                }
        }
        
        //存入请求
        let requestId = request.requestId ?? NetworkService.makeRequestId()
        store(request: afRequest, for: requestId)
        
        // 设置 afRequest 到 request 对象中
        request.afRequest = afRequest
        
        afRequest.response {[weak self] response in
            switch response.result {
            case let .success(json):
//               let json2 = "{\n  \"success\" : false,\n  \"data\" : {\n  \"success\" : false,\n  \"data\" : null,\n  \"retCode\" : -200006,\n  \"retMsg\" : \"主播未开播\",\n  \"bodyEncry\" : null,\n  \"extMap\" : null\n},\n  \"retCode\" : -200006,\n  \"retMsg\" : \"主播未开播\",\n  \"bodyEncry\" : null,\n  \"extMap\" : null\n}"
                guard let rst = json, var decoded = T.deserialize(from: rst) else {
                    var requestError = configuration.requestError.init(code: .http(response.response?.statusCode ?? 0))
                    requestError.responseModel = T()
                    requestError.responseObj = json
                    configuration.requestConfig?.requestFailure(request: request, error: requestError)
                    completion(.failure(requestError))
                    return
                }
                
                var responseJson = ""
                
                if let obj = try? JSONSerialization.jsonObject(with: rst, options: []),
                   let jsonData = try? JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted]),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    responseJson = jsonString
                }
#if DEBUG
                decoded.responseJson = responseJson
#endif
                if decoded.isBusinessSuccess {
                    configuration.requestConfig?.requestSuccess(request: request, response: decoded)
                    completion(.success(decoded))
                } else {
                    var requestError = configuration.requestError.init(code: .http(response.response?.statusCode ?? 0))
                    requestError.responseModel = decoded
                    configuration.requestConfig?.requestFailure(request: request, error: requestError)
                    completion(.failure(requestError))
                }

            case let .failure(error):
                let requestError = configuration.requestError.init(code: .http(error.responseCode ?? 0), error: error)
                configuration.requestConfig?.requestFailure(request: request, error: requestError)
                completion(.failure(requestError))
            }
            self?.removeRequest(for: requestId)
        }
    }
}

public extension NetworkService{
    static func makeRequestId() -> String {
        return ProcessInfo.processInfo.globallyUniqueString.replacingOccurrences(of: "-", with: "")
    }
}

public extension NetworkService {
    // 取消请求
     func cancel(id: String) {
        lockQueue.sync {
            let req = requests[id]
            req?.cancel()
        }
        removeRequest(for: id)
    }
    // 取消所有请求
     func cancelAll() {
        lockQueue.sync {
            requests.values.forEach { $0.cancel() }
        }
        lockQueue.async(flags: .barrier) { [weak self] in
            self?.requests.removeAll()
        }
    }
    
}

private extension NetworkService {
    
    private func store(request: Request, for id: String) {
        lockQueue.async(flags: .barrier) { [weak self] in
            self?.requests[id] = request
        }
    }
    
    private func removeRequest(for id: String) {
        lockQueue.async(flags: .barrier) { [weak self] in
            self?.requests.removeValue(forKey: id)
        }
    }
}

private extension NetworkService {

    func isValidURL(_ url: String) -> Bool {
        url.hasPrefix("http://") || url.hasPrefix("https://")
    }
}



private extension NetworkService {
    static func createSessionConfig(
        timeout: TimeInterval,
        globalHeaders: [String: String]?
    ) -> URLSessionConfiguration {
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = timeout
        sessionConfig.timeoutIntervalForResource = timeout
        sessionConfig.httpAdditionalHeaders = globalHeaders
        sessionConfig.requestCachePolicy = .reloadIgnoringLocalCacheData
        return sessionConfig
    }
    
}
