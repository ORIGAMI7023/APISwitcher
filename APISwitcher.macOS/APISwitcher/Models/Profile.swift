//
//  Profile.swift
//  APISwitcher
//
//  配置模型
//

import Foundation

struct Profile: Identifiable, Codable, Equatable, Sendable {
    var name: String
    var isActive: Bool = false
    var settings: ClaudeSettings

    // 计算属性：根据名称生成稳定的 ID
    var id: String {
        name
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

    static func == (lhs: Profile, rhs: Profile) -> Bool {
        lhs.id == rhs.id
    }
}
