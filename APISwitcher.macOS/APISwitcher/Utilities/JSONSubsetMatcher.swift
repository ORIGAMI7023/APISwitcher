//
//  JSONSubsetMatcher.swift
//  APISwitcher
//
//  JSON 子集匹配工具，用于判断配置是否激活
//

import Foundation

class JSONSubsetMatcher {
    /// 判断 subset 是否为 superset 的子集
    static func isSubset(_ subset: [String: Any], of superset: [String: Any]) -> Bool {
        for (key, subValue) in subset {
            guard let superValue = superset[key] else {
                return false
            }

            if !valuesMatch(subValue, superValue) {
                return false
            }
        }
        return true
    }

    /// 递归比较两个值是否匹配
    private static func valuesMatch(_ v1: Any, _ v2: Any) -> Bool {
        // 处理字典
        if let d1 = v1 as? [String: Any], let d2 = v2 as? [String: Any] {
            return isSubset(d1, of: d2)
        }

        // 处理数组
        if let a1 = v1 as? [Any], let a2 = v2 as? [Any] {
            return arraysEqual(a1, a2)
        }

        // 处理字符串
        if let s1 = v1 as? String, let s2 = v2 as? String {
            return s1 == s2
        }

        // 处理布尔值
        if let b1 = v1 as? Bool, let b2 = v2 as? Bool {
            return b1 == b2
        }

        // 处理数字（Int、Double 互相兼容）
        if let n1 = numericValue(v1), let n2 = numericValue(v2) {
            return abs(n1 - n2) < 0.0001
        }

        // 处理 null
        if v1 is NSNull && v2 is NSNull {
            return true
        }

        return false
    }

    /// 比较两个数组是否相等（顺序和内容都要一致）
    private static func arraysEqual(_ a1: [Any], _ a2: [Any]) -> Bool {
        guard a1.count == a2.count else {
            return false
        }

        for (index, value1) in a1.enumerated() {
            if !valuesMatch(value1, a2[index]) {
                return false
            }
        }

        return true
    }

    /// 提取数值（支持 Int、Double）
    private static func numericValue(_ value: Any) -> Double? {
        if let intValue = value as? Int {
            return Double(intValue)
        }
        if let doubleValue = value as? Double {
            return doubleValue
        }
        return nil
    }
}
