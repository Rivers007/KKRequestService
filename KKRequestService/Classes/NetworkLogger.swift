import Foundation
import Alamofire

final class NetworkLogger: EventMonitor {
    
    let queue = DispatchQueue(label: "network.logger.queue")
    
    func requestDidResume(_ request: Request) {
        KKPrint("""
        
        🚀🚀🚀🚀🚀 [REQUEST START] 🚀🚀🚀🚀🚀
        ================================================
        URL: \(request.request?.url?.absoluteString ?? "")
        METHOD: \(request.request?.httpMethod ?? "")
        HEADERS: \(request.request?.headers ?? [])
        BODY: \(bodyString(from: request.request))
        ------------------------------------------------
        cURL:
        \(request.cURLDescription())
        =================================================
        """,pre: "\n\n",terminator: "\n")
    }
    
    func request(_ request: DataRequest, didParseResponse response: DataResponse<Data?, AFError>) {
        
        let url = request.request?.url?.absoluteString ?? ""
        let status = response.response?.statusCode ?? -1
        let resultDescription = formatResult(response.result)
        
        KKPrint("""
        
        ✅✅✅✅✅✅ [RESPONSE] ✅✅✅✅✅
        ================================================
        URL: \(url)
        STATUS: \(status)
        RESULT:
        \(resultDescription)
        =================================================
        📣📣📣📣📣 [REQUEST END] 📣📣📣📣📣
        """,terminator: "\n\n")
    }
    
    func requestDidFinish(_ request: Request) {
        if let duration = request.metrics?.taskInterval.duration {
            KKPrint("⏱ [DURATION] \(String(format: "%.3f", duration))s")
        }
    }
}

private extension NetworkLogger {
    
    func bodyString(from request: URLRequest?) -> String {
        guard
            let req = request,
            let data = req.httpBody,
            !data.isEmpty
        else { return "(empty)" }
        
        if let json = try? JSONSerialization.jsonObject(with: data, options: []),
           let pretty = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted]),
           let body = String(data: pretty, encoding: .utf8) {
            return body
        }
        
        return String(data: data, encoding: .utf8) ?? "(binary data)"
    }
    
    func formatResult(_ result: Result<Data?, AFError>) -> String {
        switch result {
        case .success(let data):
            guard let data, !data.isEmpty else { return "(empty)" }
            
            if let json = try? JSONSerialization.jsonObject(with: data, options: []),
               let pretty = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted]),
               let text = String(data: pretty, encoding: .utf8) {
                return text
            }
            
            return String(data: data, encoding: .utf8) ?? "(binary data)"
            
        case .failure(let error):
            return "❌ ERROR:\n\(error.localizedDescription)"
        }
    }
}

