//
//  ViewController.swift
//  KKRequestService
//
//  Created by 江贵铸 on 12/14/2025.
//  Copyright (c) 2025 江贵铸. All rights reserved.
//

import UIKit
import KKRequestService


struct Asdsds: KKCodable {
    
    public var success: Bool?
    public var retCode: String?
    public var retMsg: String?
}

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let btn = UIButton(type: .custom)
        btn.setTitle("请求", for: .normal)
        btn.backgroundColor = .cyan
        btn.addTarget(self, action: #selector(btnClick), for: .touchUpInside)
        self.view.addSubview(btn)
        btn.frame = CGRect(x: 100, y: 200, width: 60, height: 60)
        
    }

    @objc func btnClick() {
        test1()
    }
    
    func test3() {
      
    }
    
    func test1() {
        RequestBuilder<ResponseModel<Asdsds>>(path: APIEnum.sendGift)
            .setParameters(["giftId": 2786,
                            "giftCount":10,
                            "anchorUid":9999955872,
                            "comboId":412341234123412,
                            "giftType":0,
                            "scene":0,
                            "upgradeId":0,
                            "prankProjectId":208])
            .setMethod(.post)
            .setEncoding(.urlHttpBody)
            .sendRequest { data in
              KKPrint("")
            }failureClosure: { error in
                switch error.code {
                case .networkUnavailable:
                    KKPrint("")
                case .http(let code):
                    if code == 200 {
                        print("")
                    }
                default:
                    KKPrint("")
                }
//                if error.code == 200 {
//                    print(error.responseModel!.responseJson)
//                }
            }
//            .sendRequest { result in
//                            switch result{
//                            case .success(let response):
//                                print("")
//                                break
//                            case .failure(let error):
//                                print("")
//                                if let requestError = error as? KKRequestError {
//                                    if requestError.code == 0 {
//
//                                    }
//                                }
//
//                                break
//                            }
//                        }
            }
//            .sendRequest<DefaultRequestError> { result in
//            switch result{
//            case .success(let response):
//                print("")
//                break
//            case .failure(let error):
//                print("")
////                if error.code {
////
////                }
//                break
//            }
//        }
//    }
    
    func test2() {
//        RequestBuilder<ResponseModel<String>>(path: APIEnum.verifyReceipt)
//            .setBaseUrl("https://sandbox.itunes.apple.com/")
//            .setParameters(["receipt-data": "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",
//                            "exclude-old-transactions":true])
//            .setMethod(.post)
//            .setEncoding(.json)
//            .sendRequest { result in
//            switch result{
//            case .success(let response):
//                print("")
//                break
//            case .failure(let error):
//                print("")
//                break
//            }
//        }
    }
}

