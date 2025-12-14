//
//  ConfigService.swift
//  APISwitcher
//
//  配置文件管理服务
//

import Foundation

class ConfigService {
    private let profilesPath: URL
    private let claudeSettingsPath: URL
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init() {
        self.profilesPath = PathHelper.getProfilesPath()
        self.claudeSettingsPath = PathHelper.getClaudeSettingsPath()

        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    }

    /// 加载所有配置
    func loadProfiles() throws -> [Profile] {
        // 确保文件存在
        if !FileManager.default.fileExists(atPath: profilesPath.path) {
            return []
        }

        let data = try Data(contentsOf: profilesPath)
        return try decoder.decode([Profile].self, from: data)
    }

    /// 保存配置
    func saveProfiles(_ profiles: [Profile]) throws {
        try PathHelper.ensureDirectoryExists(for: profilesPath)
        let data = try encoder.encode(profiles)
        try data.write(to: profilesPath, options: .atomic)
    }

    /// 加载 Claude 当前设置
    func loadClaudeSettings() throws -> ClaudeSettings {
        guard FileManager.default.fileExists(atPath: claudeSettingsPath.path) else {
            throw ConfigError.claudeSettingsNotFound
        }

        let data = try Data(contentsOf: claudeSettingsPath)
        return try decoder.decode(ClaudeSettings.self, from: data)
    }

    /// 切换配置（写入 Claude 设置文件）
    func switchProfile(_ profile: Profile) throws {
        try PathHelper.ensureDirectoryExists(for: claudeSettingsPath)
        let data = try encoder.encode(profile.settings)
        try data.write(to: claudeSettingsPath, options: .atomic)

        // 调试：打印写入的内容
        print("✅ 已切换到配置: \(profile.name)")
        print("📁 写入路径: \(claudeSettingsPath.path)")
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📝 写入内容:\n\(jsonString)")
        }
    }

    /// 标记激活的配置（通过匹配关键字段）
    func markActiveProfile(_ profiles: [Profile]) -> [Profile] {
        guard let currentSettings = try? loadClaudeSettings() else {
            print("⚠️ 无法加载当前 Claude 设置")
            return profiles
        }

        let currentDict = currentSettings.toDictionary()

        // 提取当前设置的关键字段
        let currentEnv = currentDict["env"] as? [String: Any] ?? [:]
        let currentBaseUrl = currentEnv["ANTHROPIC_BASE_URL"] as? String ?? ""
        let currentAuthToken = currentEnv["ANTHROPIC_AUTH_TOKEN"] as? String ?? ""

        print("🔍 当前 Claude 设置:")
        print("   BASE_URL: \(currentBaseUrl)")
        print("   AUTH_TOKEN: \(currentAuthToken.prefix(20))...")

        return profiles.map { profile in
            var updated = profile
            let profileDict = profile.settings.toDictionary()

            // 提取配置的关键字段
            let profileEnv = profileDict["env"] as? [String: Any] ?? [:]
            let profileBaseUrl = profileEnv["ANTHROPIC_BASE_URL"] as? String ?? ""
            let profileAuthToken = profileEnv["ANTHROPIC_AUTH_TOKEN"] as? String ?? ""

            // 只有两个关键字段都匹配才认为是激活的配置
            updated.isActive = !profileBaseUrl.isEmpty &&
                               !profileAuthToken.isEmpty &&
                               profileBaseUrl == currentBaseUrl &&
                               profileAuthToken == currentAuthToken

            print("   配置[\(profile.name)]: baseUrl=\(profileBaseUrl.prefix(30))... token=\(profileAuthToken.prefix(20))... -> isActive=\(updated.isActive)")

            return updated
        }
    }

    /// 添加配置
    func addProfile(_ profile: Profile) throws {
        var profiles = try loadProfiles()
        profiles.append(profile)
        try saveProfiles(profiles)
    }

    /// 更新配置
    func updateProfile(_ profile: Profile) throws {
        var profiles = try loadProfiles()
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[index] = profile
            try saveProfiles(profiles)
        } else {
            throw ConfigError.profileNotFound
        }
    }

    /// 删除配置
    func deleteProfile(_ profile: Profile) throws {
        var profiles = try loadProfiles()
        profiles.removeAll { $0.id == profile.id }
        try saveProfiles(profiles)
    }
}

enum ConfigError: LocalizedError {
    case claudeSettingsNotFound
    case profileNotFound

    var errorDescription: String? {
        switch self {
        case .claudeSettingsNotFound:
            return "未找到 Claude 设置文件 (~/.claude/settings.json)"
        case .profileNotFound:
            return "配置不存在"
        }
    }
}
