//
//  ClaudeSettings.swift
//  APISwitcher
//
//  Claude 配置模型，支持动态 JSON 属性
//

import Foundation

struct ClaudeSettings: Codable, Equatable, Sendable {
    var alwaysThinkingEnabled: Bool?
    var env: [String: String]?

    // 动态存储其他未知属性
    private var additionalProperties: [String: AnyCodableValue] = [:]

    private enum CodingKeys: String, CodingKey {
        case alwaysThinkingEnabled, env
    }

    init(alwaysThinkingEnabled: Bool? = false, env: [String: String]? = nil) {
        self.alwaysThinkingEnabled = alwaysThinkingEnabled
        self.env = env
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)

        alwaysThinkingEnabled = try? container.decode(Bool.self, forKey: DynamicCodingKeys(stringValue: "alwaysThinkingEnabled")!)
        env = try? container.decode([String: String].self, forKey: DynamicCodingKeys(stringValue: "env")!)

        for key in container.allKeys {
            if !["alwaysThinkingEnabled", "env"].contains(key.stringValue) {
                if let value = try? container.decode(AnyCodableValue.self, forKey: key) {
                    additionalProperties[key.stringValue] = value
                }
            }
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKeys.self)

        if let alwaysThinkingEnabled = alwaysThinkingEnabled {
            try container.encode(alwaysThinkingEnabled, forKey: DynamicCodingKeys(stringValue: "alwaysThinkingEnabled")!)
        }
        if let env = env {
            try container.encode(env, forKey: DynamicCodingKeys(stringValue: "env")!)
        }

        for (key, value) in additionalProperties {
            try container.encode(value, forKey: DynamicCodingKeys(stringValue: key)!)
        }
    }

    /// 转换为字典（用于 JSON 子集匹配）
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]

        if let alwaysThinkingEnabled = alwaysThinkingEnabled {
            dict["alwaysThinkingEnabled"] = alwaysThinkingEnabled
        }

        if let env = env {
            dict["env"] = env
        }

        for (key, value) in additionalProperties {
            dict[key] = value.toAny()
        }

        return dict
    }
}

/// 动态编码键
struct DynamicCodingKeys: CodingKey {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
}
