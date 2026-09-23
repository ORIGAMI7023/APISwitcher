//
//  ConfigService.swift
//  APISwitcher
//
//  配置文件管理服务
//

import Foundation
import AppKit

class ConfigService {
    private let profilesPath: URL
    private let claudeSettingsPath: URL
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    // 暴露路径供外部使用
    var appProfilesPath: URL { profilesPath }
    var settingsPath: URL { claudeSettingsPath }

    init() {
        self.profilesPath = PathHelper.getProfilesPath()
        self.claudeSettingsPath = PathHelper.getClaudeSettingsPath()

        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    }

    /// 使用默认编辑器打开文件
    func openFileWithDefaultEditor(_ fileURL: URL) throws {
        // 如果文件不存在，先尝试创建默认内容
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            try PathHelper.ensureDirectoryExists(for: fileURL)
            if fileURL.lastPathComponent == "settings.json" {
                let emptyJson = "{}\n"
                try emptyJson.write(to: fileURL, atomically: true, encoding: .utf8)
            } else if fileURL.lastPathComponent == "app_profiles.json" {
                let emptyArray = "[]\n"
                try emptyArray.write(to: fileURL, atomically: true, encoding: .utf8)
            }
        }

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw ConfigError.fileNotFound(fileURL.path)
        }

        NSWorkspace.shared.open(fileURL)
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

    /// 判断配置是否为官方配置（没有自定义 env 且没有顶层 BaseUrl / Token）
    func isOfficialProfile(_ profile: Profile) -> Bool {
        let dict = profile.settings.toDictionary()
        let env = dict["env"] as? [String: Any] ?? [:]
        let baseUrl = (env["ANTHROPIC_BASE_URL"] as? String) ?? (dict["ANTHROPIC_BASE_URL"] as? String) ?? ""
        let authToken = (env["ANTHROPIC_AUTH_TOKEN"] as? String) ?? (dict["ANTHROPIC_AUTH_TOKEN"] as? String) ?? ""
        return baseUrl.isEmpty && authToken.isEmpty
    }

    /// 切换配置（写入 Claude 设置文件）
    func switchProfile(_ profile: Profile) throws {
        try PathHelper.ensureDirectoryExists(for: claudeSettingsPath)

        var newSettings = profile.settings
        if !isOfficialProfile(profile) {
            if newSettings.env == nil {
                newSettings.env = [:]
            }
            newSettings.env?["CLAUDE_CODE_ATTRIBUTION_HEADER"] = "0"
        }

        // 读取已有 settings.json 做增量合并，保留 permissions、hooks、mcpServers 等原生配置
        var finalDict: [String: Any] = [:]
        if FileManager.default.fileExists(atPath: claudeSettingsPath.path),
           let existingData = try? Data(contentsOf: claudeSettingsPath),
           let existingObj = try? JSONSerialization.jsonObject(with: existingData) as? [String: Any] {
            finalDict = existingObj
        }

        // 将新配置的内容合并进来
        let newDict = newSettings.toDictionary()
        if newSettings.env == nil {
            finalDict.removeValue(forKey: "env")
        }
        // 清除顶层可能残留的旧版键
        finalDict.removeValue(forKey: "ANTHROPIC_AUTH_TOKEN")
        finalDict.removeValue(forKey: "ANTHROPIC_BASE_URL")
        finalDict.removeValue(forKey: "ANTHROPIC_MODEL")
        finalDict.removeValue(forKey: "ANTHROPIC_DEFAULT_HAIKU_MODEL")
        finalDict.removeValue(forKey: "ANTHROPIC_DEFAULT_SONNET_MODEL")
        finalDict.removeValue(forKey: "ANTHROPIC_DEFAULT_OPUS_MODEL")

        for (k, v) in newDict {
            finalDict[k] = v
        }

        let mergedData = try JSONSerialization.data(withJSONObject: finalDict, options: [.prettyPrinted, .sortedKeys])
        try mergedData.write(to: claudeSettingsPath, options: .atomic)

        print("✅ 已切换到配置: \(profile.name)")
        print("📁 写入路径: \(claudeSettingsPath.path)")
    }

    /// 标记激活的配置（通过匹配关键字段）
    func markActiveProfile(_ profiles: [Profile]) -> [Profile] {
        guard let currentSettings = try? loadClaudeSettings() else {
            print("⚠️ 无法加载当前 Claude 设置")
            return profiles
        }

        let currentDict = currentSettings.toDictionary()

        // 提取当前设置的关键字段（兼容 env 格式与顶层格式）
        let currentEnv = currentDict["env"] as? [String: Any] ?? [:]
        let currentBaseUrl = (currentEnv["ANTHROPIC_BASE_URL"] as? String) ?? (currentDict["ANTHROPIC_BASE_URL"] as? String) ?? ""
        let currentAuthToken = (currentEnv["ANTHROPIC_AUTH_TOKEN"] as? String) ?? (currentDict["ANTHROPIC_AUTH_TOKEN"] as? String) ?? ""

        print("🔍 当前 Claude 设置:")
        print("   BASE_URL: \(currentBaseUrl)")
        print("   AUTH_TOKEN: \(currentAuthToken.isEmpty ? "[未配置]" : "[已配置]")")

        return profiles.map { profile in
            var updated = profile
            let profileDict = profile.settings.toDictionary()

            // 提取配置的关键字段（兼容 env 格式与顶层格式）
            let profileEnv = profileDict["env"] as? [String: Any] ?? [:]
            let profileBaseUrl = (profileEnv["ANTHROPIC_BASE_URL"] as? String) ?? (profileDict["ANTHROPIC_BASE_URL"] as? String) ?? ""
            let profileAuthToken = (profileEnv["ANTHROPIC_AUTH_TOKEN"] as? String) ?? (profileDict["ANTHROPIC_AUTH_TOKEN"] as? String) ?? ""

            // 判断是否匹配
            if profileBaseUrl.isEmpty && profileAuthToken.isEmpty {
                // 配置没有自定义 env / base_url（官方配置），匹配当前也没有自定义 env 的情况
                updated.isActive = currentBaseUrl.isEmpty && currentAuthToken.isEmpty
            } else {
                // 配置有自定义 env，需要 BaseUrl 和 Token 完全匹配
                updated.isActive = profileBaseUrl == currentBaseUrl && profileAuthToken == currentAuthToken
            }

            print("   配置[\(profile.name)]: isActive=\(updated.isActive)")

            return updated
        }
    }

    /// 添加配置
    func addProfile(_ profile: Profile) throws {
        var profiles = try loadProfiles()
        if profiles.contains(where: { $0.name.caseInsensitiveCompare(profile.name) == .orderedSame }) {
            throw ConfigError.duplicateProfileName(profile.name)
        }
        profiles.append(profile)
        try saveProfiles(profiles)
    }

    /// 更新配置
    func updateProfile(oldName: String, updatedProfile: Profile) throws {
        var profiles = try loadProfiles()
        guard let index = profiles.firstIndex(where: { $0.name == oldName }) else {
            throw ConfigError.profileNotFound
        }

        // 如果修改了名称，检查新名称是否重复（排除当前正在编辑的项目，支持大小写修改）
        if oldName != updatedProfile.name {
            if profiles.enumerated().contains(where: { i, p in i != index && p.name.caseInsensitiveCompare(updatedProfile.name) == .orderedSame }) {
                throw ConfigError.duplicateProfileName(updatedProfile.name)
            }
        }

        profiles[index] = updatedProfile
        try saveProfiles(profiles)
    }

    /// 删除配置
    func deleteProfile(_ profile: Profile) throws {
        var profiles = try loadProfiles()
        if profiles.count <= 1 {
            throw ConfigError.cannotDeleteLastProfile
        }
        profiles.removeAll { $0.id == profile.id }
        try saveProfiles(profiles)
    }
}

enum ConfigError: LocalizedError {
    case claudeSettingsNotFound
    case profileNotFound
    case duplicateProfileName(String)
    case cannotDeleteLastProfile
    case fileNotFound(String)

    var errorDescription: String? {
        switch self {
        case .claudeSettingsNotFound:
            return "未找到 Claude 设置文件 (~/.claude/settings.json)"
        case .profileNotFound:
            return "配置不存在"
        case .duplicateProfileName(let name):
            return "配置名称 \"\(name)\" 已存在"
        case .cannotDeleteLastProfile:
            return "不能删除最后一个配置"
        case .fileNotFound(let path):
            return "文件不存在: \(path)"
        }
    }
}
