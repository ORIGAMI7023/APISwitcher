//
//  ProfileFormViewModel.swift
//  APISwitcher
//
//  配置表单 ViewModel
//

import Foundation
import SwiftUI

@MainActor
protocol ProfileFormDelegate: AnyObject {
    func didSaveProfile(_ profile: Profile, oldName: String?, isNew: Bool)
    func didCancelForm()
}

@MainActor
@Observable
class ProfileFormViewModel {
    // 基本信息
    var name: String

    // 必填设置
    var authToken: String
    var baseUrl: String

    // 可选模型设置
    var defaultModel: String
    var defaultHaikuModel: String
    var defaultSonnetModel: String
    var defaultOpusModel: String

    var errorMessage: String?

    private let originalProfile: Profile?
    private weak var delegate: (any ProfileFormDelegate)?

    var isNew: Bool {
        originalProfile == nil
    }

    var isOfficial: Bool {
        guard let profile = originalProfile else { return false }
        let dict = profile.settings.toDictionary()
        let env = dict["env"] as? [String: Any] ?? [:]
        let baseUrl = (env["ANTHROPIC_BASE_URL"] as? String) ?? (dict["ANTHROPIC_BASE_URL"] as? String) ?? ""
        let authToken = (env["ANTHROPIC_AUTH_TOKEN"] as? String) ?? (dict["ANTHROPIC_AUTH_TOKEN"] as? String) ?? ""
        return baseUrl.isEmpty && authToken.isEmpty
    }

    var title: String {
        isNew ? "添加配置" : "编辑配置"
    }

    init(profile: Profile? = nil, delegate: (any ProfileFormDelegate)? = nil) {
        self.originalProfile = profile
        self.delegate = delegate

        // 初始化字段
        self.name = profile?.name ?? ""

        // 从 settings 中提取值（兼容 env 对象、顶层属性以及 claude 嵌套对象等格式）
        let dict = profile?.settings.toDictionary() ?? [:]
        let env = (dict["env"] as? [String: Any]) ?? [:]
        let claudeDict = dict["claude"] as? [String: Any] ?? [:]
        self.authToken = (env["ANTHROPIC_AUTH_TOKEN"] as? String) ?? (dict["ANTHROPIC_AUTH_TOKEN"] as? String) ?? (claudeDict["apiKey"] as? String) ?? ""
        self.baseUrl = (env["ANTHROPIC_BASE_URL"] as? String) ?? (dict["ANTHROPIC_BASE_URL"] as? String) ?? (claudeDict["baseURL"] as? String) ?? ""
        self.defaultModel = (env["ANTHROPIC_MODEL"] as? String) ?? (dict["ANTHROPIC_MODEL"] as? String) ?? (dict["model"] as? String) ?? (claudeDict["model"] as? String) ?? ""
        self.defaultHaikuModel = (env["ANTHROPIC_DEFAULT_HAIKU_MODEL"] as? String) ?? (dict["ANTHROPIC_DEFAULT_HAIKU_MODEL"] as? String) ?? ""
        self.defaultSonnetModel = (env["ANTHROPIC_DEFAULT_SONNET_MODEL"] as? String) ?? (dict["ANTHROPIC_DEFAULT_SONNET_MODEL"] as? String) ?? ""
        self.defaultOpusModel = (env["ANTHROPIC_DEFAULT_OPUS_MODEL"] as? String) ?? (dict["ANTHROPIC_DEFAULT_OPUS_MODEL"] as? String) ?? ""
    }

    /// 验证表单
    func validate() -> Bool {
        errorMessage = nil

        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        if trimmedName.isEmpty {
            errorMessage = "请输入配置名称"
            return false
        }

        // 如果是官方配置且没有填 baseUrl/token，允许只修改配置名称
        if isOfficial && authToken.trimmingCharacters(in: .whitespaces).isEmpty && baseUrl.trimmingCharacters(in: .whitespaces).isEmpty {
            return true
        }

        if authToken.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "请输入 API Key"
            return false
        }

        let trimmedBaseUrl = baseUrl.trimmingCharacters(in: .whitespaces)
        if trimmedBaseUrl.isEmpty {
            errorMessage = "请输入 Base URL"
            return false
        }

        if let url = URL(string: trimmedBaseUrl), url.scheme != nil, url.host != nil {
            // URL 格式有效
        } else {
            errorMessage = "Base URL 格式不正确（例如: https://api.example.com）"
            return false
        }

        return true
    }

    /// 保存，成功返回 true，失败返回 false
    @discardableResult
    func save() -> Bool {
        guard validate() else { return false }

        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedToken = authToken.trimmingCharacters(in: .whitespaces)
        let trimmedBaseUrl = baseUrl.trimmingCharacters(in: .whitespaces)

        var env: [String: String] = [:]

        if !trimmedToken.isEmpty {
            env["ANTHROPIC_AUTH_TOKEN"] = trimmedToken
        }
        if !trimmedBaseUrl.isEmpty {
            env["ANTHROPIC_BASE_URL"] = trimmedBaseUrl
        }

        // 可选项（只有非空才添加）
        let trimmedDefaultModel = defaultModel.trimmingCharacters(in: .whitespaces)
        if !trimmedDefaultModel.isEmpty {
            env["ANTHROPIC_MODEL"] = trimmedDefaultModel
        }

        let trimmedHaikuModel = defaultHaikuModel.trimmingCharacters(in: .whitespaces)
        if !trimmedHaikuModel.isEmpty {
            env["ANTHROPIC_DEFAULT_HAIKU_MODEL"] = trimmedHaikuModel
        }

        let trimmedSonnetModel = defaultSonnetModel.trimmingCharacters(in: .whitespaces)
        if !trimmedSonnetModel.isEmpty {
            env["ANTHROPIC_DEFAULT_SONNET_MODEL"] = trimmedSonnetModel
        }

        let trimmedOpusModel = defaultOpusModel.trimmingCharacters(in: .whitespaces)
        if !trimmedOpusModel.isEmpty {
            env["ANTHROPIC_DEFAULT_OPUS_MODEL"] = trimmedOpusModel
        }

        if !isOfficial && !env.isEmpty {
            env["API_TIMEOUT_MS"] = "3000000"
            env["CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC"] = "1"
        }

        // 保留原配置中的未知属性（如 mcpServers 等），同时清理可能被迁移到 env 的顶层旧键
        var additionalProps = originalProfile?.settings.additionalProperties ?? [:]
        additionalProps.removeValue(forKey: "ANTHROPIC_AUTH_TOKEN")
        additionalProps.removeValue(forKey: "ANTHROPIC_BASE_URL")
        additionalProps.removeValue(forKey: "ANTHROPIC_MODEL")
        additionalProps.removeValue(forKey: "ANTHROPIC_DEFAULT_HAIKU_MODEL")
        additionalProps.removeValue(forKey: "ANTHROPIC_DEFAULT_SONNET_MODEL")
        additionalProps.removeValue(forKey: "ANTHROPIC_DEFAULT_OPUS_MODEL")
        additionalProps.removeValue(forKey: "API_TIMEOUT_MS")
        additionalProps.removeValue(forKey: "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC")
        additionalProps.removeValue(forKey: "CLAUDE_CODE_ATTRIBUTION_HEADER")
        additionalProps.removeValue(forKey: "model")

        // 创建 settings
        let settings = ClaudeSettings(
            alwaysThinkingEnabled: originalProfile?.settings.alwaysThinkingEnabled ?? false,
            env: env.isEmpty ? nil : env,
            additionalProperties: additionalProps
        )

        // 创建 profile，保留原本的扩展属性（如 balanceApi、subscriptionApi 等）
        let profile = Profile(
            name: trimmedName,
            isActive: originalProfile?.isActive ?? false,
            settings: settings,
            additionalProperties: originalProfile?.additionalProperties ?? [:]
        )

        delegate?.didSaveProfile(profile, oldName: originalProfile?.name, isNew: isNew)
        return true
    }

    /// 取消
    func cancel() {
        delegate?.didCancelForm()
    }
}
