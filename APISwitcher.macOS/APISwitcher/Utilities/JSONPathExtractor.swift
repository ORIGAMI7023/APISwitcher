//
//  JSONPathExtractor.swift
//  APISwitcher
//
//  JSON Path 解析工具（简化版）
//

import Foundation

class JSONPathExtractor {
    /// 从 JSON 数据中提取指定路径的值
    /// 支持格式：$.data.balance 或 data.balance
    static func extract(from json: [String: Any], path: String) -> Any? {
        // 移除 $ 前缀
        let cleanPath = path.hasPrefix("$.") ? String(path.dropFirst(2)) : path

        // 分割路径
        let components = cleanPath.split(separator: ".").map { String($0) }

        var current: Any = json

        for component in components {
            // 处理数组索引（如 data[0]）
            if component.contains("[") && component.contains("]") {
                let parts = component.components(separatedBy: "[")
                let key = parts[0]
                let indexStr = parts[1].replacingOccurrences(of: "]", with: "")

                if let dict = current as? [String: Any],
                   let array = dict[key] as? [Any],
                   let index = Int(indexStr),
                   index < array.count {
                    current = array[index]
                } else {
                    return nil
                }
            } else {
                // 普通键访问
                if let dict = current as? [String: Any] {
                    guard let value = dict[component] else {
                        return nil
                    }
                    current = value
                } else {
                    return nil
                }
            }
        }

        return current
    }

    /// 提取并转换为 Double（用于余额）
    static func extractDouble(from json: [String: Any], path: String) -> Double? {
        guard let value = extract(from: json, path: path) else {
            return nil
        }

        if let doubleValue = value as? Double {
            return doubleValue
        }
        if let intValue = value as? Int {
            return Double(intValue)
        }
        if let stringValue = value as? String {
            return Double(stringValue)
        }

        return nil
    }

    /// 提取并转换为字符串
    static func extractString(from json: [String: Any], path: String) -> String? {
        guard let value = extract(from: json, path: path) else {
            return nil
        }

        if let stringValue = value as? String {
            return stringValue
        }

        return "\(value)"
    }
}
