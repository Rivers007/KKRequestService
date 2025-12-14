//
//  JSONValue.swift
//  KKRequestServiceDemo
//
//  Created by River on 2025/12/3.
//

import Foundation

// MARK: - JSONValue

public enum JSONValue: Codable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let str = try? container.decode(String.self) {
            self = .string(str)
        } else if let int = try? container.decode(Int.self) {
            self = .int(int)
        } else if let dbl = try? container.decode(Double.self) {
            self = .double(dbl)
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let object = try? container.decode([String: JSONValue].self) {
            self = .object(object)
        } else if let array = try? container.decode([JSONValue].self) {
            self = .array(array)
        } else {
            self = .null
        }
    }

    func toAny() -> Any? {
        switch self {
        case let .string(str):
            str
        case let .int(int):
            int
        case let .double(dbl):
            dbl
        case let .bool(bool):
            bool
        case let .object(obj):
            obj.mapValues { $0.toAny() }
        case let .array(arr):
            arr.map { $0.toAny() }
        case .null:
            nil
        }
    }
}
