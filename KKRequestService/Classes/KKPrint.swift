//
//  KKPrint.swift
//  KKRequestServiceDemo
//
//  Created by River on 2025/12/8.
//

import Foundation

public func KKPrint(
    _ items: Any...,
    separator: String = " ",
    pre: String = "",
    terminator: String = "\n"
) {
    #if DEBUG
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    let time = formatter.string(from: Date())

    let output = items.map { "\($0)" }.joined(separator: separator)
    Swift.print("\(pre)[\(time)] \(output)\n", terminator: terminator)
    #endif
}
