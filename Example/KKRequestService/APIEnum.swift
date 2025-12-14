//
//  APIEnum.swift
//  KKRequestServiceDemo
//
//  Created by 江贵铸 on 2025/12/6.
//
import KKRequestService

enum APIEnum: String, APIConfigurable {
    
    static var noTokenPaths: [String]{
        [APIEnum.sendGift.rawValue]
    }
    
    var path: String{
        rawValue
    }
    
    case sendGift = "kuxiu-gift/room/sendGift"
    case verifyReceipt = "verifyReceipt"
}
