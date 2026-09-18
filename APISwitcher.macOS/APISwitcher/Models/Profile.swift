//
//  Profile.swift
//  APISwitcher
//
//  配置模型
//

import Foundation

struct Profile: Identifiable, Codable, Equatable, Sendable {
    var name: String
    var settings: ClaudeSettings

    // 运行时状态（不编码到 JSON）
    var isActive: Bool = false

    // 保留其他扩展属性（例如 balanceApi、subscriptionApi 等），防止跨平台保存时数据丢失
    var additionalProperties: [String: AnyCodableValue] = [:]

    // 计算属性：根据名称生成稳定的 ID
    var id: String {
        name
    }

    init(
        name: String,
        isActive: Bool = false,
        settings: ClaudeSettings,
        additionalProperties: [String: AnyCodableValue] = [:]
    ) {
        self.name = name
        self.isActive = isActive
        self.settings = settings
        self.additionalProperties = additionalProperties
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)
        name = try container.decode(String.self, forKey: DynamicCodingKeys(stringValue: "name")!)
        settings = try container.decode(ClaudeSettings.self, forKey: DynamicCodingKeys(stringValue: "settings")!)
        isActive = false // 运行时计算，不从文件读取

        for key in container.allKeys {
            if !["name", "settings", "isActive"].contains(key.stringValue) {
                if let value = try? container.decode(AnyCodableValue.self, forKey: key) {
                    additionalProperties[key.stringValue] = value
                }
            }
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKeys.self)
        try container.encode(name, forKey: DynamicCodingKeys(stringValue: "name")!)
        try container.encode(settings, forKey: DynamicCodingKeys(stringValue: "settings")!)
        // isActive 不编码
        for (key, value) in additionalProperties {
            try container.encode(value, forKey: DynamicCodingKeys(stringValue: key)!)
        }
    }

    static func == (lhs: Profile, rhs: Profile) -> Bool {
        lhs.id == rhs.id
    }
}
