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
    func didSaveProfile(_ profile: Profile, isNew: Bool)
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
    private weak var delegate: ProfileFormDelegate?

    var isNew: Bool {
        originalProfile == nil
    }

    var title: String {
        isNew ? "添加配置" : "编辑配置"
    }

    init(profile: Profile? = nil, delegate: ProfileFormDelegate? = nil) {
        self.originalProfile = profile
        self.delegate = delegate

        // 初始化字段
        self.name = profile?.name ?? ""

        // 从 settings.env 中提取值
        let env = profile?.settings.env ?? [:]
        self.authToken = env["ANTHROPIC_AUTH_TOKEN"] ?? ""
        self.baseUrl = env["ANTHROPIC_BASE_URL"] ?? ""
        self.defaultModel = env["ANTHROPIC_MODEL"] ?? ""
        self.defaultHaikuModel = env["ANTHROPIC_DEFAULT_HAIKU_MODEL"] ?? ""
        self.defaultSonnetModel = env["ANTHROPIC_DEFAULT_SONNET_MODEL"] ?? ""
        self.defaultOpusModel = env["ANTHROPIC_DEFAULT_OPUS_MODEL"] ?? ""
    }

    /// 验证表单
    func validate() -> Bool {
        errorMessage = nil

        if name.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "请输入配置名称"
            return false
        }

        if authToken.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "请输入 API Key"
            return false
        }

        if baseUrl.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "请输入 Base URL"
            return false
        }

        return true
    }

    /// 保存
    func save() {
        guard validate() else { return }

        // 构建 env 字典（只包含非空值）
        var env: [String: String] = [:]

        // 必填项
        env["ANTHROPIC_AUTH_TOKEN"] = authToken.trimmingCharacters(in: .whitespaces)
        env["ANTHROPIC_BASE_URL"] = baseUrl.trimmingCharacters(in: .whitespaces)

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

        // 固定值
        env["API_TIMEOUT_MS"] = "3000000"
        env["CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC"] = "1"

        // 创建 settings
        let settings = ClaudeSettings(
            alwaysThinkingEnabled: false,
            env: env
        )

        // 创建 profile
        let profile = Profile(
            name: name.trimmingCharacters(in: .whitespaces),
            settings: settings
        )

        delegate?.didSaveProfile(profile, isNew: isNew)
    }

    /// 取消
    func cancel() {
        delegate?.didCancelForm()
    }
}
