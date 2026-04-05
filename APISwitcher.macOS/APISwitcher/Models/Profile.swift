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

    // 计算属性：根据名称生成稳定的 ID
    var id: String {
        name
    }

    enum CodingKeys: String, CodingKey {
        case name, settings
    }

    init(
        name: String,
        isActive: Bool = false,
        settings: ClaudeSettings
    ) {
        self.name = name
        self.isActive = isActive
        self.settings = settings
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        settings = try container.decode(ClaudeSettings.self, forKey: .settings)
        isActive = false // 运行时计算，不从文件读取
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(settings, forKey: .settings)
        // isActive 不编码
    }

    static func == (lhs: Profile, rhs: Profile) -> Bool {
        lhs.id == rhs.id
    }
}
